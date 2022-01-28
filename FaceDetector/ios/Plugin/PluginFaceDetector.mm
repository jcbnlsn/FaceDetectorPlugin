//
//  PluginFaceDetector.mm
//
//  Copyright (c) 2016 Jacob Nielsen. All rights reserved.
//

#import "PluginFaceDetector.h"

#include "CoronaRuntime.h"
#include "CoronaAssert.h"
#include "CoronaEvent.h"
#include "CoronaLua.h"
#include "CoronaLibrary.h"

#import <UIKit/UIKit.h>

// -- Stack dump ----------------------------------------------------------------

/*
static void stackDump (lua_State *L) {
    int i;
    int top = lua_gettop(L);
    for (i = 1; i <= top; i++) {
        int t = lua_type(L, i);
        switch (t) {
                
            case LUA_TSTRING:
                printf("`%s'", lua_tostring(L, i));
                break;
                
            case LUA_TBOOLEAN:
                printf(lua_toboolean(L, i) ? "true" : "false");
                break;
                
            case LUA_TNUMBER:
                printf("%g", lua_tonumber(L, i));
                break;
                
            default:
                printf("%s", lua_typename(L, t));
                break;
                
        }
        printf("  ");
    }
    printf("\n");
}
 */

// ----------------------------------------------------------------------------

class PluginFaceDetector
{
	public:
		typedef PluginFaceDetector Self;

	public:
		static const char kName[];
		static const char kEvent[];

	protected:
		PluginFaceDetector();

	public:
		bool Initialize( CoronaLuaRef listener );

	public:
		CoronaLuaRef GetListener() const { return fListener; }

	public:
		static int Open( lua_State *L );

	protected:
		static int Finalizer( lua_State *L );

	public:
		static Self *ToLibrary( lua_State *L );

	public:
		static int track( lua_State *L );

	private:
		CoronaLuaRef fListener;
};

// ----------------------------------------------------------------------------

// This corresponds to the name of the library, e.g. [Lua] require "plugin.library"
const char PluginFaceDetector::kName[] = "plugin.faceDetector";

// This corresponds to the event name, e.g. [Lua] event.name
const char PluginFaceDetector::kEvent[] = "faceDetector";

PluginFaceDetector::PluginFaceDetector()
:	fListener( NULL )
{
}

bool
PluginFaceDetector::Initialize( CoronaLuaRef listener )
{
	// Can only initialize listener once
	bool result = ( NULL == fListener );

	if ( result )
	{
		fListener = listener;
	}

	return result;
}

int
PluginFaceDetector::Open( lua_State *L )
{
	// Register __gc callback
	const char kMetatableName[] = __FILE__; // Globally unique string to prevent collision
	CoronaLuaInitializeGCMetatable( L, kMetatableName, Finalizer );

	// Functions in library
	const luaL_Reg kVTable[] =
	{
		{ "track", track },

		{ NULL, NULL }
	};

	// Set library as upvalue for each library function
	Self *library = new Self;
	CoronaLuaPushUserdata( L, library, kMetatableName );

	luaL_openlib( L, kName, kVTable, 1 ); // leave "library" on top of stack

	return 1;
}

int
PluginFaceDetector::Finalizer( lua_State *L )
{
	Self *library = (Self *)CoronaLuaToUserdata( L, 1 );

	CoronaLuaDeleteRef( L, library->GetListener() );

	delete library;

	return 0;
}

PluginFaceDetector *
PluginFaceDetector::ToLibrary( lua_State *L )
{
	// library is pushed as part of the closure
	Self *library = (Self *)CoronaLuaToUserdata( L, lua_upvalueindex( 1 ) );
	return library;
}

// [Lua] library.detect( imagePath, listener )
int
PluginFaceDetector::track( lua_State *L )
{
    //stackDump(L);
    
    const char *imagePath = lua_tostring( L, 1 );
    if ( ! imagePath )
    {
        luaL_error( L, "Image path expected" );
    }
    
    const char *accuracy = nil;
    NSDictionary *opts = nil;
    
    if ( lua_type( L, 2 ) == LUA_TSTRING )
    {
        accuracy = lua_tostring( L, 2 );
    
        if ( accuracy && (strcmp(accuracy, "low") == 0)) {
            opts = @{ CIDetectorAccuracy : CIDetectorAccuracyLow };
        } else if ( accuracy && (strcmp(accuracy, "high") == 0)) {
            opts = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh };
        } else if ( accuracy ) {
            opts = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh };
            luaL_error( L, "Accuracy should be either 'high' or 'low'" );
        }
        
    } else {
        opts = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh };
    }
    
    //NSLog(@"Path: %@", [NSString stringWithUTF8String:imagePath]);

    // Load the picture for face detection
    UIImageView* source = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:[NSString stringWithUTF8String:imagePath]]];
    int sourceHeight = source.image.size.height;
    CIImage* image = [CIImage imageWithCGImage:source.image.CGImage];
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil options:opts];
    NSArray* features = [detector featuresInImage:image];
    
    // Listener
	Corona::Lua::Ref listenerRef = NULL;
    
	const char *eventName = "faceDetector";
	const char *eventType = "data";
		
	// Create native reference to listener
	if ( Corona::Lua::IsListener( L, -1, eventName ) )
	{
		listenerRef = Corona::Lua::NewRef( L, -1 );
	}
	else
	{
		luaL_error( L, "Listener expected, got nil" );
	}
    
    // Create listener event data
    if ( listenerRef )
    {
        // Event name
        Corona::Lua::NewEvent( L, eventName );
        
        // Event type
        lua_pushstring( L, eventType );
        lua_setfield( L, -2, CoronaEventTypeKey() );
        
        lua_newtable(L);

        int count = 0;
        
        for (CIFaceFeature *f in features) {
        
            count++;
            
            // Create table for current face
            lua_newtable(L); // face table
            
            lua_newtable(L); // bounds table
            lua_pushnumber( L, f.bounds.origin.x+(f.bounds.size.width/2) );
            lua_setfield( L, -2, "x" );
            lua_pushnumber( L, sourceHeight-f.bounds.origin.y-(f.bounds.size.height/2) );
            lua_setfield( L, -2, "y" );
            lua_pushnumber( L, f.bounds.size.width );
            lua_setfield( L, -2, "width" );
            lua_pushnumber( L, f.bounds.size.height );
            lua_setfield( L, -2, "height" );
            
            lua_setfield( L, -2, "bounds" ); // close bounds table
            
            if (f.hasLeftEyePosition) {
                //NSLog(@"Left eye %g %g", f.leftEyePosition.x, f.leftEyePosition.y);
                lua_newtable(L); // LeftEyePosition table
                lua_pushnumber( L, f.leftEyePosition.x );
                lua_setfield( L, -2, "x" );
                lua_pushnumber( L, sourceHeight-f.leftEyePosition.y );
                lua_setfield( L, -2, "y" );
                
                lua_setfield( L, -2, "leftEyePosition" ); // close LeftEyePosition table
            }
            
            if (f.hasRightEyePosition) {
                //NSLog(@"Left eye %g %g", f.leftEyePosition.x, f.leftEyePosition.y);
                lua_newtable(L); // RightEyePosition table
                lua_pushnumber( L, f.rightEyePosition.x );
                lua_setfield( L, -2, "x" );
                lua_pushnumber( L, sourceHeight-f.rightEyePosition.y );
                lua_setfield( L, -2, "y" );
                
                lua_setfield( L, -2, "rightEyePosition" ); // close RightEyePosition table
            }
            
            if (f.hasMouthPosition) {
                //NSLog(@"Left eye %g %g", f.leftEyePosition.x, f.leftEyePosition.y);
                lua_newtable(L); // MouthPosition table
                lua_pushnumber( L, f.mouthPosition.x );
                lua_setfield( L, -2, "x" );
                lua_pushnumber( L, sourceHeight-f.mouthPosition.y );
                lua_setfield( L, -2, "y" );
                
                lua_setfield( L, -2, "mouthPosition" ); // close MouthPosition table
            }

            lua_rawseti(L, -2, count); // close face table
        }
        
        lua_setfield( L, -2, "faces" );
        
        // Dispatch the event
        Corona::Lua::DispatchEvent( L, listenerRef, 1 );
    }
    
    // Release 
    [source release];
    
	return 0;
}

// ----------------------------------------------------------------------------

CORONA_EXPORT int luaopen_plugin_faceDetector( lua_State *L )
{
	return PluginFaceDetector::Open( L );
}
