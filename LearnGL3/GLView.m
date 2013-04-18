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

#define STRINGIFY(A)    #A
#import "Shaders/SimpleShader.vsh"
#import "Shaders/SimpleShader.fsh"



@interface GLView () {
    GLuint _program;
    GLint _attribPosition;
    GLint _attribColor;
}

@property (strong, nonatomic) EAGLContext *context;

- (void)drawView:(CADisplayLink *)displayLink;
- (void)drawTriangle;

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
        
        // Create display link
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView:)];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        // Build program
        GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(vertexShader, 1, &SimpleVertexShader, NULL);
        glCompileShader(vertexShader);
        
        GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(fragmentShader, 1, &SimpleFragmentShader, NULL);
        glCompileShader(fragmentShader);
        
        _program = glCreateProgram();
        glAttachShader(_program, vertexShader);
        glAttachShader(_program, fragmentShader);
        glLinkProgram(_program);
        
        _attribPosition = glGetAttribLocation(_program, "a_position");
        _attribColor = glGetAttribLocation(_program, "a_color");
        
        glUseProgram(_program);
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

- (void)drawView:(CADisplayLink *)displayLink
{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self drawTriangle];
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)drawTriangle
{
    glEnableVertexAttribArray(_attribPosition);
    glEnableVertexAttribArray(_attribColor);
    
    GLfloat vertices[] =
    {
        -0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f,
        0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f,
        0.0f, 0.5f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f
    };
    
    glVertexAttribPointer(_attribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(float) * 7, vertices);
    glVertexAttribPointer(_attribColor, 4, GL_FLOAT, GL_FALSE, sizeof(float) * 7, &vertices[3]);
    
    glDrawArrays(GL_LINE_LOOP, 0, 3);
    
    glDisableVertexAttribArray(_attribPosition);
    glDisableVertexAttribArray(_attribColor);
}

@end





