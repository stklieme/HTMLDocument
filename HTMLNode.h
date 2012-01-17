/*###################################################################################
 #																					#
 #    HTMLNode.h																	#
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

@interface HTMLNode : NSObject {
    NSError *xpathError;
	xmlNode * xmlNode_;
}

// property to catch XPath errors 
@property (retain)  NSError *xpathError;

#pragma mark - init methods
#pragma mark class
// Returns a HTMLNode object initialized with a xml node pointer of xmllib

+ (HTMLNode *)nodeWithXMLNode:(xmlNode *)xmlNode; // convenience initializer

#pragma mark instance
- (id)initWithXMLNode:(xmlNode *)xmlNode;

#pragma mark - navigation
// Node navigation relative to current node (self)

@property (readonly) HTMLNode *parent; // Returns the parent node
@property (readonly) HTMLNode *nextSibling; // Returns the next sibling
@property (readonly) HTMLNode *previousSibling; // Returns the previous sibling
@property (readonly) HTMLNode *firstChild; // Returns the first child
@property (readonly) HTMLNode *lastChild; // Returns the last child


// Returns the first level of children
@property (readonly) NSArray *children;

// Returns the number of children
@property (readonly) NSUInteger childCount;

// Returns the child at given index
- (HTMLNode *)childAtIndex:(NSUInteger)index;


#pragma mark - attributes and values of current node (self)

// Returns the attribute value matching the name
- (NSString *)attributeForName:(NSString *)attributeName;

// Returns all attributes and values as dictionary
@property (readonly) NSDictionary *attributes;

// Returns the tag name
@property (readonly) NSString *tagName;

// Returns the value for the class attribute
@property (readonly) NSString *className;

// Returns the value for the href attribute
@property (readonly) NSString *hrefValue;

// Returns the value for the src attribute
@property (readonly) NSString *srcValue;

// Returns the integer value
@property (readonly) NSInteger integerValue;

// Returns the double value
@property (readonly) double doubleValue;

// Returns the double value of a string for a given locale identifier e.g. en_US or fr_CH
// The locale identifier must conform to http://www.iso.org/iso/country_names_and_code_elements
// and http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
// if a nil value is passed, the current locale is used
- (double )doubleValueOfString:(NSString *)string forLocaleIdentifier:(NSString *)identifier;

// Returns the double value of the string value for a given locale identifier
- (double )doubleValueForLocaleIdentifier:(NSString *)identifier;

// Returns the double value of the text content for a given locale identifier
- (double )contentDoubleValueForLocaleIdentifier:(NSString *)identifier;

// Returns the date value of a string for a given date format and time zone
// The date format must conform to http://unicode.org/reports/tr35/tr35-10.html#Date_Format_Patterns
- (NSDate *)dateValueFromString:(NSString *)string format:(NSString *)dateFormat timeZone:(NSTimeZone *)timeZone;

// Returns the date value of the string value for a given date format and time zone
- (NSDate *)dateValueForFormat:(NSString *)dateFormat timeZone:(NSTimeZone *)timeZone;

// Returns the date value of the text content for a given date format and time zone
- (NSDate *)contentDateValueForFormat:(NSString *)dateFormat timeZone:(NSTimeZone *)timeZone;

// Returns the date value of the string value for a given date format and system time zone
- (NSDate *)dateValueForFormat:(NSString *)dateFormat;

// Returns the date value  of the text content for a given date format and system time zone
- (NSDate *)contentDateValueForFormat:(NSString *)dateFormat;

// Returns the raw string value
@property (readonly) NSString *rawStringValue;

// Returns the string value trimmed by whitespace and newline characters
@property (readonly) NSString *stringValue;

// Returns the string value trimmed by whitespace and newline characters and
// collapsing all multiple occurrences of whitespace and newline characters within the string into a single space
@property (readonly) NSString *stringValueCollapsingWhitespace;

// Returns the raw html text dump
@property (readonly) NSString *HTMLString;

// Returns an array of all text content of children
// each array item is trimmed by whitespace and newline characters
@property (readonly) NSArray *textContentOfChildren;

// Returns the element type
@property (readonly) xmlElementType elementType;

// Boolean check for specific xml node types
@property (readonly) BOOL isAttributeNode;
@property (readonly) BOOL isDocumentNode;
@property (readonly) BOOL isElementNode;
@property (readonly) BOOL isTextNode;

#pragma mark - contents of current node and its descendants (descendant-or-self)

// Returns the raw text content of descendant-or-self
@property (readonly) NSString *rawTextContent;

// Returns the text content of descendant-or-self trimmed by whitespace and newline characters
@property (readonly) NSString *textContent;

// Returns the text content of descendant-or-self trimmed by whitespace and newline characters and
// collapsing all multiple occurrences of whitespace and newline characters within the string into a single space
@property (readonly) NSString *textContentCollapsingWhitespace;

// Returns an array of all text content of descendant-or-self
// each array item is trimmed by whitespace and newline characters
@property (readonly) NSArray *textContentOfDescendants;

// Returns the raw html text dump of descendant-or-self
@property (readonly) NSString *HTMLContent;


#pragma mark - Query method declarations

// Note: In the category HTMLNode+XPath all appropriate query methods begin with node instead of descendant

// Returns first descendant / child node with a matching attribute name and value
- (HTMLNode *)descendantWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;
- (HTMLNode *)childWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;

// Returns first descendant / child  node with a matching attribute name and containing value
- (HTMLNode *)descendantWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;
- (HTMLNode *)childWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;

// Returns all descendant / child  nodes with a matching attribute name and value
- (NSArray *)descendantsWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;
- (NSArray *)childrenWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;

// Returns all descendant / child  nodes with a matching attribute name and containing value
- (NSArray *)descendantsWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;
- (NSArray *)childrenWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;

// Returns first descendant / child  node with a matching attribute name
- (HTMLNode *)descendantWithAttribute:(NSString *)attributeName;
- (HTMLNode *)childWithAttribute:(NSString *)attributeName;

// Returns all descendant / child  nodes with a matching attribute name
- (NSArray *)descendantsWithAttribute:(NSString *)attributeName;
- (NSArray *)childrenWithAttribute:(NSString *)attributeName;

// Returns first descendant / child  node with a matching class attribute name
- (HTMLNode *)descendantWithClass:(NSString *)classValue;
- (HTMLNode *)childWithClass:(NSString *)classValue;

// Returns all descendant / child  nodes with a matching class attribute name
- (NSArray *)descendantsWithClass:(NSString *)classValue;
- (NSArray *)childrenWithClass:(NSString *)classValue;

// Returns first descendant / child  node with a matching tag name
- (HTMLNode *)descendantOfTag:(NSString *)tagName;
- (HTMLNode *)childOfTag:(NSString *)tagName;

// Returns all descendant / child nodes with a matching tag name
- (NSArray *)descendantsOfTag:(NSString *)tagName;
- (NSArray *)childrenOfTag:(NSString *)tagName;


@end
