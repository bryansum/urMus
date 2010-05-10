/*
 *  httpServer.h
 *  urMus
 *
 *  Created by Bryan Summersett on 5/6/10.
 *  Copyright 2010 Student. All rights reserved.
 *
 */

#ifndef http_server_h
#define http_server_h

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */
  
const char *http_ip_address(void);
const char *http_ip_port(void);

/* start the web server in a new thread. web_root should be the parent directory of 
   html, and where all the resources are located. doc_root is where all user
   uploaded files should be saved. */
void http_start(const char *web_root, const char *doc_root);

void http_stop(void);
  
typedef struct lua_State lua_State;

// write and execute eval_buffers. These are thread-safe. 

/* returns NULL on success, or else the lua error string */
char *eval_buffer_write(const char *buf);
void eval_buffer_exec(lua_State *lua);
	
#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* http_server_h */
