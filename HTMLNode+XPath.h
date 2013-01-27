/*###################################################################################
 #																					#
 #    HTMLNode+XPath.h                                                              #
 #      Category of HTMLNode for XPath support                                      #
 #																					#
 #    Copyright © 2011 by Stefan Klieme                                             #
 #																					#
 #	  Objective-C wrapper for HTML parser of libxml2								#
 #																					#
 #	  Version 1.5 - 27. Jan 2013                                                    #
 #																					#
 #    usage:     add #import HTMLNode+XPath.h                                       #
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

#import "HTMLNode.h"

#if !defined(__clang__) || __clang_major__ < 3

#ifndef __bridge_retained
#define __bridge_retained
#endif

#ifndef __bridge_transfer
#define __bridge_transfer
#endif

#endif


@interface HTMLNode (XPath)

// Xpath query methods


// Returns first descendant node for a XPath query
- (HTMLNode *)nodeForXPath:(NSString *)query error:(NSError **)error;
- (HTMLNode *)nodeForXPath:(NSString *)query;

// Returns all descendant nodes for a XPath query
- (NSArray *)nodesForXPath:(NSString *)query error:(NSError **)error;
- (NSArray *)nodesForXPath:(NSString *)query;


// Note: In the HTMLNode main class all appropriate query methods begin with descendant instead of node 

// Returns first/all descendant node(s) with a matching tag name 
- (HTMLNode *)nodeOfTag:(NSString *)tagName error:(NSError **)error;
- (HTMLNode *)nodeOfTag:(NSString *)tagName;
- (NSArray *)nodesOfTag:(NSString *)tagName error:(NSError **)error;
- (NSArray *)nodesOfTag:(NSString *)tagName;

// Returns first/all descendant node(s) with a matching tag name and matching attribute name
- (HTMLNode *)nodeOfTag:(NSString *)tagName withAttribute:(NSString *)attributeName error:(NSError **)error;
- (HTMLNode *)nodeOfTag:(NSString *)tagName withAttribute:(NSString *)attributeName;
- (NSArray *)nodesOfTag:(NSString *)tagName withAttribute:(NSString *)attributeName error:(NSError **)error;
- (NSArray *)nodesOfTag:(NSString *)tagName withAttribute:(NSString *)attributeName;

// Returns first/all descendant node(s) with a matching attribute name
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName error:(NSError **)error;
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName;
- (NSArray *)nodesWithAttribute:(NSString *)attributeName error:(NSError **)error;
- (NSArray *)nodesWithAttribute:(NSString *)attributeName;

// Returns first/all descendant node(s) with a matching attribute name and value
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueMatches:(NSString *)value error:(NSError **)error;
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueMatches:(NSString *)value;
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueMatches:(NSString *)value error:(NSError **)error;
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueMatches:(NSString *)value;

// Returns first/all descendant node(s) with a matching attribute name and matching the beginning of its value
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)value error:(NSError **)error;
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)value;
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)value error:(NSError **)error;
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)value;

// Returns first/all descendant node(s) with a matching attribute name and matching the end of its value
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)value error:(NSError **)error;
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)value;
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)value error:(NSError **)error;
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)value;

// Returns first/all descendant node(s) with a matching attribute name and containing its value
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueContains:(NSString *)value error:(NSError **)error;
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueContains:(NSString *)value;
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueContains:(NSString *)value error:(NSError **)error;
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueContains:(NSString *)value;

// Returns first/all descendant node(s) with a matching class attribute name
- (HTMLNode *)nodeWithClass:(NSString *)classValue error:(NSError **)error;
- (HTMLNode *)nodeWithClass:(NSString *)classValue;
- (NSArray *)nodesWithClass:(NSString *)classValue error:(NSError **)error;
- (NSArray *)nodesWithClass:(NSString *)classValue;


// Compare two nodes w.r.t document order with XPath
- (BOOL)isEqual:(HTMLNode *)node;

// XPath error handling
- (void)setErrorWithMessage:(NSString *)message andCode:(NSInteger)code;

@end
