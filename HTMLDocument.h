/*###################################################################################
 #																					#
 #    HTMLDocument.h																#
 #																					#
 #    Copyright © 2011 by Stefan Klieme                                             #
 #																					#
 #	  Objective-C wrapper for HTML parser of libxml2								#
 #																					#
 #	  Version 1.0 - 25 Dec 2011                                                     #
 #																					#
 #    usage:     add libxml2.dylib to frameworks                                    #
 #               add $SDKROOT/usr/include/libxml2 to target -> Header Search Paths  #
 #               add -lxml2 to target -> other linker flags                         #
 #                                                                                  #
 #																					#
 ####################################################################################
 #																					#
 # Permission is hereby granted, free of charge, to any person obtaining a copy of  #
 # this software and associated documentation files (the "Software"), to deal       #
 # in the Software without restriction, including without limitation the rights     #
 # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies #
 # of the Software, and to permit persons to whom the Software is furnished to do   #
 # so, subject to the following conditions:                                         #
 # The above copyright notice and this permission notice shall be included in       #
 # all copies or substantial portions of the Software.                              #
 # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR       #
 # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,         #
 # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE      #
 # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,# 
 # WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR     #
 # IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.	#
 #																					#
 ###################################################################################*/

#import <Foundation/Foundation.h>
#import <libxml/HTMLparser.h>
#import "HTMLNode.h"

@interface HTMLDocument : NSObject
{    
    htmlDocPtr  htmlDoc_;
    HTMLNode    *rootNode;
}

// convenience initializer methods
// default text encoding is UTF-8

+ (HTMLDocument *)documentWithData:(NSData *)data encoding:(NSStringEncoding )encoding error:(NSError **)error;
+ (HTMLDocument *)documentWithData:(NSData *)data error:(NSError **)error;
+ (HTMLDocument *)documentWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding )encoding error:(NSError **)error;
+ (HTMLDocument *)documentWithContentsOfURL:(NSURL *)url error:(NSError **)error;
+ (HTMLDocument *)documentWithHTMLString:(NSString *)string encoding:(NSStringEncoding )encoding error:(NSError **)error;
+ (HTMLDocument *)documentWithHTMLString:(NSString *)string error:(NSError **)error;

// initializer
- (id)initWithData:(NSData *)data encoding:(NSStringEncoding )encoding error:(NSError **)error; // designated initializer
- (id)initWithData:(NSData *)data error:(NSError **)error;
- (id)initWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding )encoding error:(NSError **)error;
- (id)initWithContentsOfURL:(NSURL *)url error:(NSError **)error;
- (id)initWithHTMLString:(NSString *)string encoding:(NSStringEncoding )encoding error:(NSError **)error;
- (id)initWithHTMLString:(NSString *)string error:(NSError **)error;

- (NSError *)errorForCode:(NSInteger )errorCode;

// root element (html node)
@property (readonly) HTMLNode *rootNode;

// frequently used nodes
@property (readonly) HTMLNode *head;
@property (readonly) HTMLNode *body;

// value of title tag
@property (readonly) NSString *title;


@end
