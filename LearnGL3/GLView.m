//
//  GLView.m
//  LearnGL3
//
//  Created by Sergey Alpeev on 4/18/13.
//  Copyright (c) 2013 Sergey Alpeev. All rights reserved.
//

#import "GLView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>



@interface GLView ()

@property (strong, nonatomic) EAGLContext *context;

- (void)drawView;

@end



@implementation GLView

#pragma mark - Class methods

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = YES;
        
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!self.context || ![EAGLContext setCurrentContext:self.context]) {
            return nil;
        }
        
        GLuint renderbuffer;
        glGenRenderbuffers(1, &renderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
        
        GLuint framebuffer;
        glGenFramebuffers(1, &framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);
        
        glViewport(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame));
        
        [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
        
        [self drawView];
    }
    return self;
}

- (void)dealloc
{
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

#pragma mark - Private Methods

- (void)drawView
{
    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

@end





