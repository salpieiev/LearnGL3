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
    
    GLuint _resolveFramebuffer;
    GLuint _multisampleFramebuffer;
    
    GLuint _resolveColorRenderbuffer;
    GLuint _multisampleColorRenderbuffer;
    GLuint _multisampleDepthStencilRenderbuffer;
}

@property (strong, nonatomic) EAGLContext *context;
@property (assign, nonatomic) BOOL createSnapshot;

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
        CGFloat scale = [UIScreen mainScreen].scale;
        
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.contentsScale = scale;
        
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!self.context || ![EAGLContext setCurrentContext:self.context]) {
            return nil;
        }
        
        CGFloat width = CGRectGetWidth(frame) * scale;
        CGFloat height = CGRectGetHeight(frame) * scale;
        
        // Resolve framebuffer
        glGenRenderbuffers(1, &_resolveColorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _resolveColorRenderbuffer);
        [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
        
        glGenFramebuffers(1, &_resolveFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _resolveFramebuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _resolveColorRenderbuffer);
        
        glViewport(0, 0, width, height);
        
        // Creating the multisample buffer
        glGenFramebuffers(1, &_multisampleFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _multisampleFramebuffer);
        
        glGenRenderbuffers(1, &_multisampleColorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _multisampleColorRenderbuffer);
        glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_RGBA8_OES, width, height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _multisampleColorRenderbuffer);
        
        glGenRenderbuffers(1, &_multisampleDepthStencilRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _multisampleDepthStencilRenderbuffer);
        glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_DEPTH24_STENCIL8_OES, width, height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _multisampleDepthStencilRenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, _multisampleDepthStencilRenderbuffer);
        
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

#pragma mark - User interaction

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.createSnapshot = YES;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

#pragma mark - Private Methods

- (void)drawView:(CADisplayLink *)displayLink
{
    glBindFramebuffer(GL_FRAMEBUFFER, _multisampleFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _multisampleColorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _multisampleDepthStencilRenderbuffer);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    [self drawTriangle];
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, _resolveFramebuffer);
    glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, _multisampleFramebuffer);
    glResolveMultisampleFramebufferAPPLE();
    
    const GLenum discards[] =
    {
        GL_COLOR_ATTACHMENT0,
        GL_DEPTH_ATTACHMENT,
        GL_STENCIL_ATTACHMENT
    };
    glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 3, discards);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _resolveFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _resolveColorRenderbuffer);
    
    [self createSnapshotIfNeeded];
    
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

- (UIImage *)snapshot
{
    GLint backingWidth, backingHeight;
    
    // Bind the color renderbuffer used to render the OpenGL ES view
    // If your application only creates a single color renderbuffer which is already bound at this point,
    // this call is redundant, but it is needed if you're dealing with multiple renderbuffers.
    // Note, replace "_colorRenderbuffer" with the actual name of the renderbuffer object defined in your class.
//    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    // Get the size of the backing CAEAGLLayer
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    NSInteger x = 0, y = 0, width = backingWidth, height = backingHeight;
    NSInteger dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    
    // Read pixel data from the framebuffer
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    // Create a CGImage with the pixel data
    // If your OpenGL ES content is opaque, use kCGImageAlphaNoneSkipLast to ignore the alpha channel
    // otherwise, use kCGImageAlphaPremultipliedLast
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    // OpenGL ES measures data in PIXELS
    // Create a graphics context with the target size measured in POINTS
    NSInteger widthInPoints, heightInPoints;
    if (NULL != UIGraphicsBeginImageContextWithOptions) {
        // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
        // Set the scale parameter to your OpenGL ES view's contentScaleFactor
        // so that you get a high-resolution snapshot when its value is greater than 1.0
        CGFloat scale = self.contentScaleFactor;
        widthInPoints = width / scale;
        heightInPoints = height / scale;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthInPoints, heightInPoints), NO, scale);
    }
    else {
        // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
        widthInPoints = width;
        heightInPoints = height;
        UIGraphicsBeginImageContext(CGSizeMake(widthInPoints, heightInPoints));
    }
    
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    
    // UIKit coordinate system is upside down to GL/Quartz coordinate system
    // Flip the CGImage by rendering it to the flipped bitmap context
    // The size of the destination area is measured in POINTS
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, widthInPoints, heightInPoints), iref);
    
    // Retrieve the UIImage from the current context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    // Clean up
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    
    return image;
}

- (void)createSnapshotIfNeeded
{
    if (self.createSnapshot) {
        self.createSnapshot = NO;
        
        UIImage *image = [self snapshot];
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
}

@end





