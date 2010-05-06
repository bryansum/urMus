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

extern lua_State *lua;
extern pthread_mutex_t g_lua_mutex;

static struct mg_context *ctx = NULL;

static const char *index_page = "/index.html";
static const char *http_port = "8080";

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
	int status_code = 200; const char *msg = "OK";

	char *code = mg_get_var(conn, "code");
	if (code) {
		pthread_mutex_lock(&g_lua_mutex);
		if (!luaL_dostring(lua,code)) {
			status_code = 500; 
			msg = "Internal Server Error";
		}
		pthread_mutex_unlock(&g_lua_mutex);
		mg_free(code);
	} else {
		status_code = 500;
		msg = "Internal Server Error";
	}

	mg_printf(conn, "HTTP/1.1 %d %s\r\n\r\n",status_code,msg);
}

void http_start(const char *web_root) 
{
	http_stop();
	ctx = mg_start();
	mg_set_option(ctx, "root", web_root);
	mg_set_option(ctx, "ports", http_port);
	mg_set_uri_callback(ctx, "/", &show_index, NULL);
	mg_set_uri_callback(ctx, "/eval", &eval_script, NULL);
}

void http_stop(void)
{
	if (ctx) {
		mg_stop(ctx);
	}
}

