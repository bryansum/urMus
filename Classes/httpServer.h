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
<<<<<<< HEAD
const char *http_ip_port(void);
=======
>>>>>>> f3a74e331abf0eb495d10dfc6f8abc170c237f60
void http_start(const char *web_root, const char *bundle_root);
void http_stop(void);
	
#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* http_server_h */
