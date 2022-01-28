//
//  PluginFaceDetector.h
//
//  Copyright (c) 2016 Jacob Nielsen. All rights reserved.
//

#ifndef _PluginFaceDetector_H__
#define _PluginFaceDetector_H__

#include "CoronaLua.h"
#include "CoronaMacros.h"

#import <Cocoa/Cocoa.h>

CORONA_EXPORT int luaopen_plugin_faceDetector( lua_State *L );

#endif // _PluginFaceDetector_H__
