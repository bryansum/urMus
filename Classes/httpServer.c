/*
 *  httpServer.c
 *  urMus
 *
 *  Created by Bryan Summersett on 5/6/10.
 *  Copyright 2010 Student. All rights reserved.
 *
 */
#include "httpServer.h"
#include "lua.h"
#include "lauxlib.h"
#include "mongoose.h"
#include <pthread.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <dirent.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/syslimits.h>

static struct mg_context *ctx = NULL;

static const char *index_page = "html/index.html";
static const char *http_port = "8080";

static char *doc_root = NULL;
static char *web_root = NULL;

static void 
replace_str(char **dest, const char *src)
{
  if (*dest) free(*dest);
  *dest = src ? strdup(src) : NULL;
}

static char *
get_var_or_err(struct mg_connection *conn,
							const char *var)
{
  char *out = NULL;
  if (!(out = mg_get_var(conn, var))) {
    mg_printf(conn, "HTTP/1.1 400 Bad Request\r\n"
          "Content-Type: text/plain\r\n\r\n"
          "Parameter '%s' not specified", var);
  }
  return out;
}

/* gets the directory folder specified by the 'dirtype' parameter */
static char *
get_abs_dirtype_path(struct mg_connection *conn)
{
  char *dir_type, *dir;

  if (!(dir_type = get_var_or_err(conn, "dirtype"))) {
    return NULL;
  }
  if (strcmp(dir_type, "doc") == 0) {
    dir = doc_root;
  } else if (strcmp(dir_type, "root") == 0){
    dir = web_root;
  } else {
    mg_printf(conn, "HTTP/1.1 400 Bad Request\r\n"
          "Content-Type: text/plain\r\n\r\n"
          "Parameter '%s' not valid", dir_type);
    mg_free(dir_type);
    return NULL;
  }
  return dir;
}

static int 
write_file(struct mg_connection *conn, 
           const char *fname, 
           void *buf, 
           size_t len)
{
  FILE  *fp;
  char abs_path[PATH_MAX];

  sprintf(abs_path, "%s/%s", doc_root, fname);

  if (!(fp = fopen(abs_path, "wb"))) {
    mg_printf(conn, "HTTP/1.1 500 Internal Server Error\r\n"
              "Content-Type: text/plain\r\n\r\n"
              "Can't open or create file '%s'", fname);
    return 1;
  }

	if (fwrite(buf, 1, len, fp) != len) {
    mg_printf(conn, "HTTP/1.1 500 Internal Server Error\r\n"
              "Content-Type: text/plain\r\n\r\n"
              "Can't write to file '%s'", fname);
    fclose(fp);
    return 1;
  }

  fclose(fp);
  mg_printf(conn, "HTTP/1.1 200 OK\r\n"
            "Content-Type: text/plain\r\n\r\n");
  return 0;  
}

static void
upload_script(struct mg_connection *conn,
        const struct mg_request_info *request_info,
        void *user_data)
{
  char *file_name, *buf;
  if (!(file_name = get_var_or_err(conn, "file"))
      || !(buf = get_var_or_err(conn, "contents"))) {
    return;
  }
  (void) write_file(conn, file_name, buf, strlen(buf));
}

/*
 * Uploads a generic file intercepted by a form <input type="file">. This is an
 * awful hack trying to implement RFC 1867 http://www.ietf.org/rfc/rfc1867.txt
 */ 
static void
upload_file(struct mg_connection *conn,
        const struct mg_request_info *request_info,
        void *user_data)
{
  char file_name[BUFSIZ], post_header[BUFSIZ], *cur, *end;
  size_t header_size, data_size, i;
  
  // extract header
  cur = strstr(request_info->post_data, "\r\n"); // find first header '---------WebKitFormBoundaryblah\r\n"
  header_size = cur - request_info->post_data;
  memcpy(post_header, request_info->post_data, header_size);
  *(post_header + header_size) = '\0';
  
  // extract filename and move to beginning of data
  cur = strstr(cur, "filename=\"") + 10; // find filename=" and move to the val immed. after
  for(i = 0; i < BUFSIZ && *cur != '"'; i++, cur++) file_name[i] = *cur; // copy file_name
  file_name[i] = '\0';
  cur = strstr(cur, "\r\n\r\n") + 4; // find the beginning of data
  
  // find end of file contents
  end = strstr(cur, post_header);
  
  data_size = end - cur;
  
  (void) write_file(conn, file_name, cur, data_size);
}

static void
open_file(struct mg_connection *conn,
      const struct mg_request_info *request_info,
      void *user_data)
{
  FILE  *fp;
  char *file_name, *buf, abs_path[PATH_MAX], *dir;
  long size;
  
  if (!(file_name = get_var_or_err(conn, "file"))
      || !(dir = get_abs_dirtype_path(conn))) {
    return;
  }

  sprintf(abs_path, "%s/%s", dir, file_name);
  
  if (!(fp = fopen(abs_path, "r"))) {
    mg_printf(conn, "HTTP/1.1 500 Internal Server Error\r\n"
          "Content-Type: text/plain\r\n\r\n"
          "Can't open file '%s'", abs_path);
    return;
  }
  
  // obtain file size:
  fseek(fp, 0, SEEK_END);
  size = ftell(fp);
  rewind (fp);
    
  // allocate memory to contain the whole file:
  buf = (char*) malloc (sizeof(char)*size);
  fread(buf, 1, size, fp);
  
  mg_printf(conn, "HTTP/1.1 200 OK\r\n"
        "Content-Type: text/plain\r\n"
        "Content-Length: %ld\r\n"
        "Connection: close\r\n\r\n", size);

  mg_write(conn, buf, size);
  
  mg_free(file_name);
  free(buf);
  fclose(fp);
}

static void
get_files(struct mg_connection *conn,
       const struct mg_request_info *request_info,
       void *user_data)
{
  DIR *d;
  struct dirent *de;
  char *dir;
  
  if (!(dir = get_abs_dirtype_path(conn))) {
    return;
  }

  if ((d = opendir(dir)) != NULL) {
    mg_printf(conn, "HTTP/1.1 200 OK\r\n"
          "Content-Type: application/json\r\n\r\n"
          "[");
    char first = 1;
    for(;;) {
      de = readdir(d);
      if (!de)
        break;
      if (strcmp(de->d_name, ".") != 0 &&
        strcmp(de->d_name, "..") != 0) {
        char comma;
        if (first) { comma = ' '; first = 0; }
        else comma = ',';
        mg_printf(conn, "%c\"%s\"", comma, de->d_name);
      }
    }
    closedir(d);
    mg_printf(conn, "]");
  } else {
    mg_printf(conn, "HTTP/1.1 500 Internal Server Error\r\n"
          "Content-Type: text/plain\r\n\r\n"
          "Can't open '%s'",dir);
  }
}

static void
show_index(struct mg_connection *conn,
       const struct mg_request_info *request_info,
       void *user_data)
{ 
  mg_printf(conn, "HTTP/1.1 302 Found\r\n"
        "Location: %s\r\n\r\n", index_page);
}

// Runs the given 'code' query string in the lua interpreter. 
// Totally not safe, but whatever. 
static void 
eval_script(struct mg_connection *conn,
      const struct mg_request_info *request_info,
      void *user_data) 
{
  char *code = mg_get_var(conn, "code"), *err_str;
  if (code) {
    
    // thread-safe, blocking eval call
    err_str = eval_buffer_write(code);
    if (err_str) {
        mg_printf(conn, "HTTP/1.1 500 Internal Server Error\r\n"
                  "Content-Type: text/plain\r\n\r\n"
                  "Lua error: %s", err_str);
        free(err_str);
    } else {
        mg_printf(conn, "HTTP/1.1 200 OK\r\n"
                  "Content-Type: text/plain\r\n\r\n");        
    }

    mg_free(code);
  } else {
    mg_printf(conn, "HTTP/1.1 400 Bad Request\r\n"
          "Content-Type: text/plain\r\n\r\n"
          "Parameter 'code' not specified");  
  }
}

void 
http_start(const char *web_root_, const char *doc_root_) 
{
  replace_str(&doc_root, doc_root_);
  replace_str(&web_root, web_root_);
    
  http_stop();
  ctx = mg_start();
  mg_set_option(ctx, "root", web_root);
  mg_set_option(ctx, "ports", http_port);
  mg_set_uri_callback(ctx, "/", &show_index, NULL);
  mg_set_uri_callback(ctx, "/eval", &eval_script, NULL);  
  mg_set_uri_callback(ctx, "/get_files", &get_files, NULL);
  mg_set_uri_callback(ctx, "/open_file", &open_file, NULL);
  mg_set_uri_callback(ctx, "/upload_file", &upload_file, NULL);
  mg_set_uri_callback(ctx, "/upload_script", &upload_script, NULL);
}

void 
http_stop(void)
{
  if (ctx) {
    mg_stop(ctx);
  }
}

const char* 
http_ip_address(void) 
{
  char baseHostName[BUFSIZ];
  gethostname(baseHostName, BUFSIZ);
  
  // Adjust for iPhone -- add .local to the host name 
  // iff hostname doesn't already end in .local
  char hn[BUFSIZ];
  if (!strstr(baseHostName,".local")) {
    sprintf(hn, "%s.local", baseHostName);
  } else {
    strcpy(hn, baseHostName);
  }
  
  struct hostent *host = gethostbyname(hn);
  struct hostent *gethostbyaddr(const void *addr, socklen_t len,
                  int type);
    if (host == NULL) {
    herror("resolv");
    return NULL;
  } else {
    struct in_addr **list = (struct in_addr **)host->h_addr_list;
    return inet_ntoa(*list[0]);
  }
  
  return NULL;
}

const char* http_ip_port(void)
{
  return http_port;
}

static pthread_mutex_t eval_buffer_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t eval_buffer_cond = PTHREAD_COND_INITIALIZER;
static char *eval_buffer = NULL;
/* if there's an error from evaluating the buffer, put it here */
static char *err_str = NULL;

char *
eval_buffer_write(const char *buf)
{
  char *new_error = NULL;

  pthread_mutex_lock(&eval_buffer_mutex);
  if (eval_buffer) free(eval_buffer); // overwrite if one's already here. 
  eval_buffer = strdup(buf);
  while (eval_buffer) { // should empty out after executing
    pthread_cond_wait(&eval_buffer_cond, &eval_buffer_mutex);
  }
  if (err_str) {
    new_error = strdup(err_str);
  }
  pthread_mutex_unlock(&eval_buffer_mutex);
  return new_error;
}

void
eval_buffer_exec(lua_State *lua)
{
  pthread_mutex_lock(&eval_buffer_mutex);
  if (eval_buffer) {
    /* returns > 0 if error */
    if (luaL_dostring(lua, eval_buffer)) {
      replace_str(&err_str, lua_tostring(lua, -1));
    } else {
      replace_str(&err_str, NULL);
    }
    replace_str(&eval_buffer, NULL);
  }
  pthread_mutex_unlock(&eval_buffer_mutex);
  pthread_cond_signal(&eval_buffer_cond);
}