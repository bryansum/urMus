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
void http_start(const char *web_root, const char *bundle_root);
void http_stop(void);
  
typedef struct lua_State lua_State;

// write and execute eval_buffers. These are thread-safe. 
void eval_buffer_write(const char *buf);
void eval_buffer_exec(lua_State *lua);
	
#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* http_server_h */
