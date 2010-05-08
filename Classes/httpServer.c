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

extern lua_State *lua;
extern pthread_mutex_t g_lua_mutex;

static struct mg_context *ctx = NULL;

static const char *index_page = "/index.html";
static const char *http_port = "8080";

static char *bundle_root = NULL;


static char 
*get_var_or_err(struct mg_connection *conn,
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

static int 
write_file(struct mg_connection *conn, 
           const char *fname, 
           void *buf, 
           size_t len)
{
  FILE  *fp;
  char abs_path[PATH_MAX];

  sprintf(abs_path, "%s/%s", bundle_root, fname);

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
 * Uploads a generic file intercepted by a form <input type="file">. This is probably
 * very fragile. 
 */ 
static void
upload_file(struct mg_connection *conn,
        const struct mg_request_info *request_info,
        void *user_data)
{
  char file_name[BUFSIZ], *cur;
  long header_size, data_size, i;

  cur = strstr(request_info->post_data, "filename=\"") + 10; // find filename=" and move to the val immed. after
  for(i = 0; i < BUFSIZ && *cur != '"'; i++, cur++) file_name[i] = *cur; // copy file_name
  file_name[i] = '\0';
  cur = strstr(cur, "\r\n\r\n") + 4; // find the end
  
  header_size = cur - request_info->post_data;
  data_size = request_info->post_data_len - header_size;
  
  (void) write_file(conn, file_name, cur, data_size);
}

static void
open_file(struct mg_connection *conn,
      const struct mg_request_info *request_info,
      void *user_data)
{
  FILE  *fp;
  char *file_name, *buf, abs_path[PATH_MAX];
  long size;
  
  if (!(file_name = get_var_or_err(conn, "file"))) {
    return;
  }

  sprintf(abs_path, "%s/%s", bundle_root, file_name);
  
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

  if ((d = opendir(bundle_root)) != NULL) {
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
          "Can't open '%s'",bundle_root);
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
  char *code = mg_get_var(conn, "code");
  if (code) {
    pthread_mutex_lock(&g_lua_mutex);
    if (luaL_dostring(lua,code)) {
      const char* error = lua_tostring(lua, -1);      
      mg_printf(conn, "HTTP/1.1 500 Internal Server Error\r\n"
            "Content-Type: text/plain\r\n\r\n"
            "Error: %s",error);
    } else {
      mg_printf(conn, "HTTP/1.1 200 OK\r\n"
            "Content-Type: text/plain\r\n\r\n");
    }
    pthread_mutex_unlock(&g_lua_mutex);
    mg_free(code);
  } else {
    mg_printf(conn, "HTTP/1.1 400 Bad Request\r\n"
          "Content-Type: text/plain\r\n\r\n"
          "Parameter 'code' not specified");  
  }
}

void 
http_start(const char *web_root, const char *_bundle_root) 
{
  if (bundle_root) {
    free(bundle_root);
  }
  bundle_root = strdup(_bundle_root);
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