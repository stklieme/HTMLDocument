/*###################################################################################
 #																					#
 #    HTMLNode.h																	#
 #																					#
 #    Copyright © 2011 by Stefan Klieme                                             #
 #																					#
 #	  Objective-C wrapper for HTML parser of libxml2								#
 #																					#
 #	  Version 1.5 - 27. Jan 2013                                                    #
 #																					#
 #    usage:     add libxml2.dylib to frameworks                                    #
 #               add $SDKROOT/usr/include/libxml2 to target -> Header Search Paths  #
 #               add -lxml2 to target -> other linker flags                         #
 #                                                                                  #
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
#import <libxml/tree.h>
#import <libxml/HTMLtree.h>

#define kClassKey @"class"

// ARCMacros by John Blanco
// added a macro for computed readonly properties which return always autoreleased objects

#if __has_feature(objc_arc)
    #define SAFE_ARC_PROP_RETAIN strong
    #define SAFE_ARC_READONLY_OBJ_PROP unsafe_unretained, readonly 
    #define SAFE_ARC_RELEASE(x)
    #define SAFE_ARC_AUTORELEASE(x) (x)
    #define SAFE_ARC_SUPER_DEALLOC()
#else
    #define SAFE_ARC_PROP_RETAIN retain
    #define SAFE_ARC_READONLY_OBJ_PROP readonly
    #define SAFE_ARC_RELEASE(x) ([(x) release])
    #define SAFE_ARC_AUTORELEASE(x) ([(x) autorelease])
    #define SAFE_ARC_SUPER_DEALLOC() ([super dealloc])
#endif

@interface HTMLNode : NSObject {
    NSError *xpathError;
	xmlNode * xmlNode_;
}

// property to catch XPath errors
@property (SAFE_ARC_PROP_RETAIN)  NSError *xpathError;

#pragma mark - init methods
#pragma mark class
// Returns a HTMLNode object initialized with a xml node pointer of xmllib

+ (HTMLNode *)nodeWithXMLNode:(xmlNode *)xmlNode; // convenience initializer

#pragma mark instance
- (id)initWithXMLNode:(xmlNode *)xmlNode;

#pragma mark - navigation
// Node navigation relative to current node (self)

@property (SAFE_ARC_READONLY_OBJ_PROP) HTMLNode *parent; // Returns the parent node
@property (SAFE_ARC_READONLY_OBJ_PROP) HTMLNode *nextSibling; // Returns the next sibling
@property (SAFE_ARC_READONLY_OBJ_PROP) HTMLNode *previousSibling; // Returns the previous sibling
@property (SAFE_ARC_READONLY_OBJ_PROP) HTMLNode *firstChild; // Returns the first child
@property (SAFE_ARC_READONLY_OBJ_PROP) HTMLNode *lastChild; // Returns the last child


// Returns the first level of children
@property (SAFE_ARC_READONLY_OBJ_PROP) NSArray *children;

// Returns the number of children
@property (readonly) NSUInteger childCount;

// Returns the child at given index
- (HTMLNode *)childAtIndex:(NSUInteger)index;


#pragma mark - attributes and values of current node (self)

// Returns the attribute value matching the name
- (NSString *)attributeForName:(NSString *)attributeName;

// Returns all attributes and values as dictionary
@property (SAFE_ARC_READONLY_OBJ_PROP) NSDictionary *attributes;

// Returns the tag name
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *tagName;

// Returns the value for the class attribute
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *className;

// Returns the value for the href attribute
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *hrefValue;

// Returns the value for the src attribute
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *srcValue;

// Returns the integer value
@property (readonly) NSInteger integerValue;

// Returns the double value
@property (readonly) double doubleValue;

// Returns the double value of the string value for a given locale identifier
- (double )doubleValueForLocaleIdentifier:(NSString *)identifier;

// Returns the double value of the string value for a given locale identifier considering a plus sign prefix
- (double )doubleValueForLocaleIdentifier:(NSString *)identifier consideringPlusSign:(BOOL)flag;

// Returns the double value of the text content for a given locale identifier
- (double )contentDoubleValueForLocaleIdentifier:(NSString *)identifier;

// Returns the double value of the text content for a given locale identifier considering a plus sign prefix
- (double )contentDoubleValueForLocaleIdentifier:(NSString *)identifier consideringPlusSign:(BOOL)flag;

// Returns the date value of the string value for a given date format and time zone
- (NSDate *)dateValueForFormat:(NSString *)dateFormat timeZone:(NSTimeZone *)timeZone;

// Returns the date value of the text content for a given date format and time zone
- (NSDate *)contentDateValueForFormat:(NSString *)dateFormat timeZone:(NSTimeZone *)timeZone;

// Returns the date value of the string value for a given date format and system time zone
- (NSDate *)dateValueForFormat:(NSString *)dateFormat;

// Returns the date value  of the text content for a given date format and system time zone
- (NSDate *)contentDateValueForFormat:(NSString *)dateFormat;

// Returns the raw string value
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *rawStringValue;

// Returns the string value trimmed by whitespace and newline characters
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *stringValue;

// Returns the string value trimmed by whitespace and newline characters and
// collapsing all multiple occurrences of whitespace and newline characters within the string into a single space
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *stringValueCollapsingWhitespace;

// Returns the raw html text dump
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *HTMLString;

// Returns an array of all text content of children
// each array item is trimmed by whitespace and newline characters
@property (SAFE_ARC_READONLY_OBJ_PROP) NSArray *textContentOfChildren;

// Returns the element type
@property (readonly) xmlElementType elementType;

// Boolean check for specific xml node types
@property (readonly) BOOL isAttributeNode;
@property (readonly) BOOL isDocumentNode;
@property (readonly) BOOL isElementNode;
@property (readonly) BOOL isTextNode;

#pragma mark - contents of current node and its descendants (descendant-or-self)

// Returns the raw text content of descendant-or-self
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *rawTextContent;

// Returns the text content of descendant-or-self trimmed by whitespace and newline characters
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *textContent;

// Returns the text content of descendant-or-self trimmed by whitespace and newline characters and
// collapsing all multiple occurrences of whitespace and newline characters within the string into a single space
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *textContentCollapsingWhitespace;

// Returns an array of all text content of descendant-or-self
// each array item is trimmed by whitespace and newline characters
@property (SAFE_ARC_READONLY_OBJ_PROP) NSArray *textContentOfDescendants;

// Returns the raw html text dump of descendant-or-self
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *HTMLContent;


#pragma mark - Query method declarations

// Note: In the category HTMLNode+XPath all appropriate query methods begin with node instead of descendant

// Returns first descendant / child / sibling node with a matching attribute name and value
- (HTMLNode *)descendantWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;
- (HTMLNode *)childWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;
- (HTMLNode *)siblingWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;

// Returns first descendant / child / sibling node with a matching attribute name and containing value
- (HTMLNode *)descendantWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;
- (HTMLNode *)childWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;
- (HTMLNode *)siblingWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;

// Returns all descendant / child / sibling nodes with a matching attribute name and value
- (NSArray *)descendantsWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;
- (NSArray *)childrenWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;
- (NSArray *)siblingsWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;

// Returns all descendant / child / sibling nodes with a matching attribute name and containing value
- (NSArray *)descendantsWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;
- (NSArray *)childrenWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;
- (NSArray *)siblingsWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;

// Returns first descendant / child / sibling node with a matching attribute name
- (HTMLNode *)descendantWithAttribute:(NSString *)attributeName;
- (HTMLNode *)childWithAttribute:(NSString *)attributeName;
- (HTMLNode *)siblingWithAttribute:(NSString *)attributeName;

// Returns all descendant / child / sibling nodes with a matching attribute name
- (NSArray *)descendantsWithAttribute:(NSString *)attributeName;
- (NSArray *)childrenWithAttribute:(NSString *)attributeName;
- (NSArray *)siblingsWithAttribute:(NSString *)attributeName;

// Returns first descendant / child / sibling node with a matching class attribute name
- (HTMLNode *)descendantWithClass:(NSString *)classValue;
- (HTMLNode *)childWithClass:(NSString *)classValue;
- (HTMLNode *)siblingWithClass:(NSString *)classValue;

// Returns all descendant / child / sibling nodes with a matching class attribute name
- (NSArray *)descendantsWithClass:(NSString *)classValue;
- (NSArray *)childrenWithClass:(NSString *)classValue;
- (NSArray *)siblingsWithClass:(NSString *)classValue;

// Returns first descendant / child / sibling node with a matching tag name and string value
- (HTMLNode *)descendantOfTag:(NSString *)tagName valueMatches:(NSString *)value;
- (HTMLNode *)childOfTag:(NSString *)tagName valueMatches:(NSString *)value;
- (HTMLNode *)siblingOfTag:(NSString *)tagName valueMatches:(NSString *)value;

// Returns all descendant / child / sibling nodes with a matching tag name and string value
- (NSArray *)descendantsOfTag:(NSString *)tagName valueMatches:(NSString *)value;
- (NSArray *)childrenOfTag:(NSString *)tagName valueMatches:(NSString *)value;
- (NSArray *)siblingsOfTag:(NSString *)tagName valueMatches:(NSString *)value;

// Returns first descendant / child / sibling node with a matching tag name and containing string value
- (HTMLNode *)descendantOfTag:(NSString *)tagName valueContains:(NSString *)value;
- (HTMLNode *)childOfTag:(NSString *)tagName valueContains:(NSString *)value;
- (HTMLNode *)siblingOfTag:(NSString *)tagName valueContains:(NSString *)value;

// Returns all descendant / child /sibling nodes with a matching tag name and containing string value
- (NSArray *)descendantsOfTag:(NSString *)tagName valueContains:(NSString *)value;
- (NSArray *)childrenOfTag:(NSString *)tagName valueContains:(NSString *)value;
- (NSArray *)siblingsOfTag:(NSString *)tagName valueContains:(NSString *)value;

// Returns first descendant / child / sibling node with a matching tag name
- (HTMLNode *)descendantOfTag:(NSString *)tagName;
- (HTMLNode *)childOfTag:(NSString *)tagName;
- (HTMLNode *)siblingOfTag:(NSString *)tagName;

// Returns all descendant / child / sibling nodes with a matching tag name
- (NSArray *)descendantsOfTag:(NSString *)tagName;
- (NSArray *)childrenOfTag:(NSString *)tagName;
- (NSArray *)siblingsOfTag:(NSString *)tagName;


@end
