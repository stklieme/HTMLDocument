/*###################################################################################
 #                                                                                   #
 #    HTMLNode.swift                                                                 #
 #                                                                                   #
 #    Copyright © 2014-2017 by Stefan Klieme                                         #
 #                                                                                   #
 #    Swift wrapper for HTML parser of libxml2                                       #
 #                                                                                   #
 #    Version 1.0 - 1. Sep 2017                                                      #
 #                                                                                   #
 #    usage:     add libxml2.dylib to frameworks (depends on autoload settings)      #
 #               add $SDKROOT/usr/include/libxml2 to target -> Header Search Paths   #
 #               add -lxml2 to target -> other linker flags                          #
 #               add Bridging-Header.h to your project and rename it as              #
 #                  [Modulename]-Bridging-Header.h                                   #
 #                  where [Modulename] is the module name in your project            #
 #                  or copy&paste the #import lines into your bridging header        #
 #                                                                                   #
 #####################################################################################
 #                                                                                   #
 # Permission is hereby granted, free of charge, to any person obtaining a copy of   #
 # this software and associated documentation files (the "Software"), to deal        #
 # in the Software without restriction, including without limitation the rights      #
 # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies  #
 # of the Software, and to permit persons to whom the Software is furnished to do    #
 # so, subject to the following conditions:                                          #
 # The above copyright notice and this permission notice shall be included in        #
 # all copies or substantial portions of the Software.                               #
 # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR        #
 # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,          #
 # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE       #
 # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, #
 # WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR      #
 # IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.     #
 #                                                                                   #
 ###################################################################################*/

import Foundation

private enum XMLElementType : UInt32
{
    case ELEMENT_NODE = 1, ATTRIBUTE_NODE = 2, TEXT_NODE = 3, CDATA_SECTION_NODE = 4
    case ENTITY_REF_NODE = 5, ENTITY_NODE = 6, PI_NODE = 7, COMMENT_NODE = 8
    case DOCUMENT_NODE = 9, DOCUMENT_TYPE_NODE = 10, DOCUMENT_FRAG_NODE = 11
    case NOTATION_NODE = 12, HTML_DOCUMENT_NODE = 13, DTD_NODE = 14, ELEMENT_DECL = 15
    case ATTRIBUTE_DECL = 16, ENTITY_DECL = 17, NAMESPACE_DECL = 18, XINCLUDE_START = 19
    case XINCLUDE_END = 20, DOCB_DOCUMENT_NODE = 21
}


extension String {
    
    func collapseCharacters(in characterSet: CharacterSet?, using separator: String) -> String?
    {
        if characterSet == nil { return self }
        
        let array = self.components(separatedBy: characterSet!)
        let result = array.reduce("") { "\($0)\(separator)\($1)" }
        return result
    }
    
    func collapseWhitespaceAndNewLine() -> String?
    {
        return self.collapseCharacters(in: CharacterSet.whitespacesAndNewlines, using:" ")
    }
    
    // ISO 639 identifier e.g. en_US or fr_CH
    func doubleValue(forLocaleIdentifier localeIdentifier: String?, consideringPlusSign: Bool = false) -> Double
    {
        if self.isEmpty { return 0.0 }
        let numberFormatter = NumberFormatter()
        if let identifier = localeIdentifier {
            let locale = Locale(identifier: identifier)
            numberFormatter.locale = locale
        }
        if consideringPlusSign && self.hasPrefix("+") {
            numberFormatter.positivePrefix = "+"
        }
        numberFormatter.numberStyle = .decimal
        let number = numberFormatter.number(from: self)
        
        return number?.doubleValue ?? 0.0
    }
    
    // date format e.g. @"yyyy-MM-dd 'at' HH:mm" --> 2001-01-02 at 13:00
    func dateValue(withFormat format: String, timeZone: TimeZone?) -> Date?
    {
        if self.isEmpty { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        if timeZone != nil { dateFormatter.timeZone = timeZone }
        return dateFormatter.date(from: self)
    }
    
    // convert String to UnsafePointer<xmlChar>
    
    func withXmlChar<T>(handler: (UnsafePointer<xmlChar>) throws -> T) rethrows -> T {
        let xmlstr = self.utf8CString.map { xmlChar(bitPattern: $0) }
        return try xmlstr.withUnsafeBufferPointer { try handler($0.baseAddress!) }
    }
}

// helper class to make the pointers `xmlAttr` and `xmlNode` a sequence

private class XMLSequence<T> : Sequence {
    
    typealias Element = UnsafeMutablePointer<T>?
    var current: Element
    var next: Element { return nil }
    
    init(node: Element) { self.current = node }
    
    func makeIterator() -> AnyIterator<UnsafeMutablePointer<T>> {
        return AnyIterator {
            guard let current = self.current else { return nil }
            self.current = self.next
            return current
        }
    }
}

private class XmlAttrSequence : XMLSequence<xmlAttr> {
    
    override var next: Element { return current?.pointee.next }
    override init(node: Element) { super.init(node: node) }
}

private class XmlNodeSequence : XMLSequence<xmlNode> {
    
    override var next: Element { return current?.pointee.next }
    override init(node: Element) { super.init(node: node) }
}

class HTMLNode : Sequence, Equatable, CustomStringConvertible {
    
    // MARK: Constants
    
    private let dumpBufferSize = 4000
    let kClassKey = "class"
    let kIDKey = "id"
    
    // MARK: XPath Error variables
    
    var xpathErrorCode : Int32 = 99999
    var xpathErrorMessage = "Unknown Error"

    // MARK: Private variables for the current node and its pointer
    
    let pointer : xmlNodePtr
    fileprivate let node : xmlNode
    
    // MARK: - init methods
    
    /// Initializes and returns a newly allocated HTMLNode object with a specified xmlNode pointer.
    /// - Parameters:
    ///   - pointer: The xmlNode pointer for the created node object.
    /// - Returns: An initiazlized HTMLNode object or nil if the object couldn't be created.
    
    init?(pointer: xmlNodePtr!) {
        guard let nodePointer = pointer else { return nil }
        self.pointer = nodePointer
        self.node = nodePointer.pointee
    }
    
    // MARK: - navigating methods
    
    /// The parent node.
    
    var parent : HTMLNode? {
        return HTMLNode(pointer: node.parent)
    }
    
    /// The next sibling node.
    
    var nextSibling : HTMLNode? {
        return HTMLNode(pointer: node.next)
    }
    
    /// The previous sibling node.
    
    var previousSibling : HTMLNode? {
        return HTMLNode(pointer: node.prev)
    }
    
    /// The first child node.
    
    var firstChild : HTMLNode? {
        return HTMLNode(pointer: node.children)
    }
    
    /// The last child node.
    
    var lastChild : HTMLNode? {
        return HTMLNode(pointer: node.last)
    }
    
    /// The first level of children.
    
    // delete 'where xmlNodeIsText(currentNode) == 0' to consider all the text nodes
    // see also the 'makeIterator()' function
    
    var children : [HTMLNode] {
        var array = [HTMLNode]()
        for currentNode in XmlNodeSequence(node: node.children) where xmlNodeIsText(currentNode) == 0 {
            if let node = HTMLNode(pointer: currentNode) {
                array.append(node)
            }
        }
        return array
    }
    
    /// The child node at specified index.
    /// - Parameters:
    ///   - index The specified index.
    /// - Returns: The node at given index or nil the attribute could not be found.
    
    
    func child(at index : Int) -> HTMLNode?
    {
        let childrenArray = self.children
        return (index < childrenArray.count) ? childrenArray[index] : nil
    }
    
    /// The number of children
    
    var childCount : Int {
        return Int(xmlChildElementCount(pointer))
    }
    
    // MARK: - attributes and values of current node (self)
    
    /// The attribute value of a node matching a given name.
    /// - Parameters:
    ///   - name: The name of an attribute.
    /// - Returns: The attribute value or ab empty string if the attribute could not be found.
    
    func attribute(for name : String) -> String?
    {
        return name.withXmlChar { attrName -> String? in
            if let attributeValue = xmlGetProp(pointer, attrName) {
                let result = stringFrom(xmlchar: attributeValue)
                free(attributeValue)
                return result
            }
            return nil
        }
    }
    
    /// All attributes and values as dictionary.
    
    var attributes : [String:String] {
        var result = [String:String]()
        for attribute in XmlAttrSequence(node: node.properties) {
            if let children = attribute.pointee.children,
                let name = attribute.pointee.name {
                let value = stringFrom(xmlchar: children.pointee.content)
                let key = stringFrom(xmlchar: name)
                result[key] = value
            }
        }
        return result
    }
    
    /// The tag name.
    
    var tagName : String? {
        guard let nodeName = node.name else { return nil }
        return stringFrom(xmlchar: nodeName)
    }
    
    /// The value for the class attribute.
    
    var classValue : String? {
        return attribute(for: kClassKey)
    }
    
    /// The value for the id attribute.
    
    var IDValue : String? {
        return attribute(for: kIDKey)
    }
    
    /// The value for the href attribute.
    
    var hrefValue : String? {
        return attribute(for: "href")
    }
    
    /// The value for the src attribute.
    
    var srcValue : String? {
        return attribute(for: "src")
    }
    
    /// The integer value.
    
    var integerValue : Int? {
        guard let string = self.stringValue else { return nil }
        return Int(string)
    }
    
    /// The double value.
    
    var doubleValue : Double? {
        guard let string = self.stringValue else { return nil }
        return Double(string)
    }
    
    /// Returns the double value of the string value for a specified locale identifier considering a plus sign prefix.
    /// - Parameters:
    ///   - identifier: A locale identifier. The locale identifier must conform to http://www.iso.org/iso/country_names_and_code_elements and http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
    ///   - flag: Considers the plus sign in the string if true (optional, default is false).
    /// - Returns: The double value of the string value depending on the parameters.
    
    func doubleValue(forLocaleIdentifier identifier : String, consideringPlusSign flag : Bool = false) -> Double?
    {
        return self.stringValue?.doubleValue(forLocaleIdentifier: identifier, consideringPlusSign:flag)
    }
    
    /// Returns the double value of the text content for a specified locale identifier considering a plus sign prefix.
    /// - Parameters:
    ///   - identifier: A locale identifier. The locale identifier must conform to http://www.iso.org/iso/country_names_and_code_elements and http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
    ///   - flag: Considers the plus sign in the string if true (optional, default is false).
    /// - Returns: The double value of the text content depending on the parameters.
    
    func contentDoubleValue(forLocaleIdentifier identifier : String, consideringPlusSign flag : Bool = false) -> Double?
    {
        return self.textContent?.doubleValue(forLocaleIdentifier: identifier, consideringPlusSign:flag)
    }
    
    /// Returns the date value of the string value for a specified date format and time zone.
    /// - Parameters:
    ///   - format: A date format string. The date format must conform to http://unicode.org/reports/tr35/tr35-10.html#Date_Format_Patterns
    ///   - timeZone: A time zone (optional, default is current time zone).
    /// - Returns: The date value of the string value depending on the parameters.
    
    func dateValue(withFormat format : String, timeZone : TimeZone? = nil) -> Date? // date format e.g. @"yyyy-MM-dd 'at' HH:mm" --> 2001-01-02 at 13:00
    {
        return self.stringValue?.dateValue(withFormat : format, timeZone : timeZone)
    }
    
    /// Returns the date value of the text content for a specified date format and time zone.
    /// - Parameters:
    ///   - format: A date format string. The date format must conform to http://unicode.org/reports/tr35/tr35-10.html#Date_Format_Patterns
    ///   - timeZone: A time zone (optional, default is current time zone).
    /// - Returns: The date value of the text content depending on the parameters.
    
    func contentDateValue(withFormat format : String, timeZone : TimeZone? = nil) -> Date?
    {
        return self.textContent?.dateValue(withFormat: format, timeZone:timeZone)
    }
    
    /// The raw string.
    
    var rawStringValue : String? {
        guard let content = node.children.pointee.content else { return nil }
        return stringFrom(xmlchar: content)
    }
    
    /// The string value of a node trimmed by whitespace and newline characters.
    
    var stringValue : String? {
        return self.rawStringValue?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    /// The string value of a node trimmed by whitespace and newline characters and collapsing all multiple occurrences of whitespace and newline characters within the string into a single space.
    
    var stringValueCollapsingWhitespace : String? {
        return self.stringValue?.collapseWhitespaceAndNewLine()
    }
    
    /// The raw html text dump.
    
    var HTMLString : String? {
        var result : String?
        
        if let buffer = xmlBufferCreate() {
            let err : Int32 = xmlNodeDump(buffer, nil, pointer, 0, 0)
            if err > -1 {
                result = stringFrom(xmlchar: buffer.pointee.content).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            xmlBufferFree(buffer)
        }
        return result
    }
    
    private func textContentOfChildren(nodePtr : xmlNodePtr,
                                       array : inout [String],
                                       recursive : Bool)
    {
        for currentNode in XmlNodeSequence(node: nodePtr) {
            if let content = textContent(of: currentNode), !content.isEmpty {
                let trimmedContent = content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if !trimmedContent.isEmpty {
                    array.append(trimmedContent)
                }
            }
            
            if recursive {
                textContentOfChildren(nodePtr: currentNode.pointee.children, array: &array, recursive: recursive)
            }
        }
    }
    
    /// The element type of the node.
    
    var elementType : String {
        switch node.type.rawValue {
            
        case 1: return "Element"
        case 2: return "Attribute"
        case 3: return "Text"
        case 4: return "CData Section"
        case 5: return "Entity Ref"
        case 6: return "Entity"
        case 7: return "Pi"
        case 8: return "Comment"
        case 9: return "Document"
        case 10: return "Document Type"
        case 11: return "Document Frag"
        case 12: return "Notation"
        case 13: return "HTML Document"
        case 14: return "DTD"
        case 15: return "Element Declaration"
        case 16: return "Attribute Declaration"
        case 17: return "Entity Declaration"
        case 18: return "Namespace Declaration"
        case 19: return "Xinclude Start"
        case 20: return "Xinclude End"
        case 21: return "DOCD Document"
        default: return "n/a"
        }
    }
    
    /// Is the node an attribute node.
    
    var isAttributeNode : Bool {
        return node.type.rawValue == XMLElementType.ATTRIBUTE_NODE.rawValue
    }
    
    /// Is the node a document node.
    
    var isDocumentNode : Bool {
        return node.type.rawValue == XMLElementType.HTML_DOCUMENT_NODE.rawValue
    }
    
    /// Is the node an element node.
    
    var isElementNode : Bool {
        return node.type.rawValue == XMLElementType.ELEMENT_NODE.rawValue
    }
    
    /// Is the node a text node.
    
    var isTextNode : Bool {
        return node.type.rawValue == XMLElementType.TEXT_NODE.rawValue
    }
    
    /// The array of all text content of children.
    
    var textContentOfChildren : [String] {
        var array = [String]()
        textContentOfChildren(nodePtr: node.children, array:&array, recursive:false)
        return array
    }
    
    
    // MARK: - attributes and values of current node and its descendants (descendant-or-self)
    
    private func textContent(of nodePtr : xmlNodePtr) -> String?
    {
        if let contents = xmlNodeGetContent(nodePtr) {
            defer { free(contents) }
            return stringFrom(xmlchar: contents)
        }
        return nil
    }
    
    /// The raw text content of descendant-or-self.
    
    var rawTextContent : String? {
        return textContent(of: pointer)
    }
    
    /// The text content of descendant-or-self trimmed by whitespace and newline characters.
    
    var textContent : String? {
        return textContent(of: pointer)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    /// The text content of descendant-or-self in an array, each item trimmed by whitespace and newline characters.
    
    var textContentCollapsingWhitespace : String? {
        return self.textContent?.collapseWhitespaceAndNewLine()
    }
    
    /// The text content of descendant-or-self in an array, each item trimmed by whitespace and newline characters.
    
    var textContentOfDescendants : [String] {
        var array = [String]()
        textContentOfChildren(nodePtr: node.children, array:&array, recursive:true)
        return array
    }
    
    /// The raw html text dump of descendant-or-self.
    
    var HTMLContent : String?  {
        
        guard let document = node.doc else { return nil }
        let xmlCharContent = document.pointee.encoding!
        
        var xmlBuffer = xmlBufferCreateSize(dumpBufferSize)
        var outputBuffer = xmlOutputBufferCreateBuffer(xmlBuffer, nil)
        
        defer {
            xmlOutputBufferClose(outputBuffer)
            xmlBufferFree(xmlBuffer)
        }
        
        let constChar = xmlCharContent.withMemoryRebound(to: Int8.self, capacity: MemoryLayout.size(ofValue: xmlCharContent)) {
            return $0
        }
        
        htmlNodeDumpOutput(outputBuffer, document, self.pointer, constChar)
        xmlOutputBufferFlush(outputBuffer)
        
        guard let content = xmlBuffer?.pointee.content else { return nil }
        return stringFrom(xmlchar: content)
    }
    
    
    // MARK: -  query methods
    // Note: In the category HTMLNode+XPath all appropriate query methods begin with node instead of descendant
    
    
    private func child(withAttribute attribute : UnsafePointer<xmlChar>,
                       nodePtr : xmlNodePtr,
                       recursive : Bool) -> HTMLNode?
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            for attr in XmlAttrSequence(node: currentNodePtr.pointee.properties) {
                if xmlStrEqual(attr.pointee.name, attribute) == 1 {
                    return HTMLNode(pointer: currentNodePtr)
                }
            }
            
            if recursive, let children = currentNodePtr.pointee.children,
                let subNode = child(withAttribute: attribute, nodePtr: children, recursive: recursive) {
                return subNode
            }
        }
        return nil
    }
    
    private func child(withAttribute attribute : UnsafePointer<xmlChar>,
                       matches value : UnsafePointer<xmlChar>,
                       nodePtr : xmlNodePtr,
                       recursive : Bool) -> HTMLNode?
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            for attr in XmlAttrSequence(node: currentNodePtr.pointee.properties) {
                if xmlStrEqual(attr.pointee.name, attribute) == 1 {
                    if xmlStrEqual(attr.pointee.children.pointee.content, value) == 1 {
                        return HTMLNode(pointer: currentNodePtr)
                    }
                }
            }
            
            if recursive, let children = currentNodePtr.pointee.children,
                let subNode = child(withAttribute: attribute, matches: value, nodePtr: children, recursive: recursive) {
                return subNode
            }
        }
        return nil
    }
    
    private func child(withAttribute attribute : UnsafePointer<xmlChar>,
                       contains value : UnsafePointer<xmlChar>,
                       nodePtr : xmlNodePtr,
                       recursive : Bool) -> HTMLNode?
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            for attr in XmlAttrSequence(node: currentNodePtr.pointee.properties) {
                if xmlStrEqual(attr.pointee.name, attribute) == 1 {
                    
                    if xmlStrstr(attr.pointee.children.pointee.content, value) != nil {
                        return HTMLNode(pointer: currentNodePtr)
                    }
                }
            }
            
            if recursive, let children = currentNodePtr.pointee.children,
                let subNode = child(withAttribute: attribute, contains: value, nodePtr: children, recursive: recursive) {
                return subNode
            }
        }
        return nil
    }
    
    private func child(withAttribute attribute : UnsafePointer<xmlChar>,
                       beginsWith value : UnsafePointer<xmlChar>,
                       nodePtr : xmlNodePtr,
                       recursive : Bool) -> HTMLNode?
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            for attr in XmlAttrSequence(node: currentNodePtr.pointee.properties) {
                if xmlStrEqual(attr.pointee.name, attribute) == 1 {
                    
                    let subString = xmlStrsub(attr.pointee.children.pointee.content, 0, xmlStrlen(value))
                    if xmlStrEqual(subString, value) == 1 {
                        return HTMLNode(pointer: currentNodePtr)
                    }
                }
            }
            
            if recursive, let children = currentNodePtr.pointee.children,
                let subNode = child(withAttribute: attribute, beginsWith: value, nodePtr: children, recursive: recursive) {
                return subNode
            }
        }
        return nil
    }
    
    private func child(withAttribute attribute : UnsafePointer<xmlChar>,
                       endsWith value : UnsafePointer<xmlChar>,
                       nodePtr : xmlNodePtr,
                       recursive : Bool) -> HTMLNode?
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            for attr in XmlAttrSequence(node: currentNodePtr.pointee.properties) {
                if xmlStrEqual(attr.pointee.name, attribute) == 1 {
                    
                    let attrContent = attr.pointee.children.pointee.content
                    let addValueLength = xmlStrlen(value)
                    let subString = xmlStrsub(attrContent, (xmlStrlen(attrContent) - addValueLength), addValueLength)
                    if xmlStrEqual(subString, value) == 1 {
                        return HTMLNode(pointer: currentNodePtr)
                    }
                }
            }
            
            if recursive, let children = currentNodePtr.pointee.children,
                let subNode = child(withAttribute: attribute, endsWith: value, nodePtr: children, recursive: recursive) {
                return subNode
            }
        }
        return nil
    }
    
    
    private func children(withAttribute attribute : UnsafePointer<xmlChar>,
                          nodePtr : xmlNodePtr,
                          array : inout [HTMLNode],
                          recursive : Bool)
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            for attr in XmlAttrSequence(node: currentNodePtr.pointee.properties) {
                if xmlStrEqual(attr.pointee.name, attribute) == 1 {
                    if let matchingNode = HTMLNode(pointer: currentNodePtr) {
                        array.append(matchingNode)
                        break
                    }
                }
            }
            
            if recursive, let childrn = currentNodePtr.pointee.children {
                children(withAttribute: attribute, nodePtr: childrn, array:&array, recursive:recursive)
            }
        }
    }
    
    private func children(withAttribute attribute : UnsafePointer<xmlChar>,
                          matches value : UnsafePointer<xmlChar>,
                          nodePtr : xmlNodePtr,
                          array : inout [HTMLNode],
                          recursive : Bool)
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            for attr in XmlAttrSequence(node: currentNodePtr.pointee.properties) {
                if xmlStrEqual(attr.pointee.name, attribute) == 1 {
                    
                    if xmlStrEqual(attr.pointee.children.pointee.content, value) == 1 {
                        if let matchingNode = HTMLNode(pointer: currentNodePtr) {
                            array.append(matchingNode)
                            break
                        }
                    }
                }
            }
            
            if recursive, let childrn = currentNodePtr.pointee.children {
                children(withAttribute: attribute, matches: value, nodePtr: childrn, array:&array, recursive:recursive)
            }
        }
    }
    
    private func children(withAttribute attribute : UnsafePointer<xmlChar>,
                          contains value : UnsafePointer<xmlChar>,
                          nodePtr : xmlNodePtr,
                          array : inout [HTMLNode],
                          recursive : Bool)
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            for attr in XmlAttrSequence(node: currentNodePtr.pointee.properties) {
                if xmlStrEqual(attr.pointee.name, attribute) == 1 {
                    
                    if xmlStrstr(attr.pointee.children.pointee.content, value) != nil {
                        if let matchingNode = HTMLNode(pointer: currentNodePtr) {
                            array.append(matchingNode)
                            break
                        }
                    }
                }
            }
            
            if recursive, let childrn = currentNodePtr.pointee.children {
                children(withAttribute: attribute, contains:value, nodePtr: childrn, array:&array, recursive:recursive)
            }
        }
    }
    
    private func children(withAttribute attribute : UnsafePointer<xmlChar>,
                          beginsWith value : UnsafePointer<xmlChar>,
                          nodePtr : xmlNodePtr,
                          array : inout [HTMLNode],
                          recursive : Bool)
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            for attr in XmlAttrSequence(node: currentNodePtr.pointee.properties) {
                if xmlStrEqual(attr.pointee.name, attribute) == 1 {
                    
                    let subString = xmlStrsub(attr.pointee.children.pointee.content, 0, xmlStrlen(value))
                    if xmlStrEqual(subString, value) == 1 {
                        if let matchingNode = HTMLNode(pointer: currentNodePtr) {
                            array.append(matchingNode)
                            break
                        }
                    }
                }
            }
            
            if recursive, let childrn = currentNodePtr.pointee.children {
                children(withAttribute: attribute, beginsWith: value, nodePtr: childrn, array:&array, recursive:recursive)
            }
        }
    }
    
    private func children(withAttribute attribute : UnsafePointer<xmlChar>,
                          endsWith value : UnsafePointer<xmlChar>,
                          nodePtr : xmlNodePtr,
                          array : inout [HTMLNode],
                          recursive : Bool)
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            for attr in XmlAttrSequence(node: currentNodePtr.pointee.properties) {
                if xmlStrEqual(attr.pointee.name, attribute) == 1 {
                    
                    let attrContent = attr.pointee.children.pointee.content
                    let addValueLength = xmlStrlen(value)
                    let subString = xmlStrsub(attrContent, (xmlStrlen(attrContent) - addValueLength), addValueLength)
                    if xmlStrEqual(subString, value) == 1 {
                        if let matchingNode = HTMLNode(pointer: currentNodePtr) {
                            array.append(matchingNode)
                            break
                        }
                    }
                }
            }
            
            if recursive, let childrn = currentNodePtr.pointee.children {
                children(withAttribute: attribute, endsWith: value, nodePtr: childrn, array:&array, recursive:recursive)
            }
        }
    }
    
    
    /// Returns the first descendant node with the specifed attribute name and value matching exactly.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The value of the attribute.
    /// - Returns: The first found descendant node or nil if no node matches the parameters.
    
    func descendant(withAttribute attribute : String, matches value : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlAttr, matches: xmlValue, nodePtr: node.children, recursive: true)
            }
        }
    }
    
    /// Returns the first child node with the specifed attribute name and value matching exactly.
    ///   - attributeName The name of the attribute.
    ///   - value: The value of the attribute.
    /// - Returns: The first found child node or nil if no node matches the parameters.
    
    func child(withAttribute attribute : String, matches value : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlAttr, matches: xmlValue, nodePtr: node.children, recursive: false)
            }
        }
    }
    
    /// Returns the first sibling node with the specifed attribute name and value matching exactly.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The value of the attribute.
    /// - Returns: The first found sibling node or nil if no node matches the parameters.
    
    func sibling(withAttribute attribute : String, matches value : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlAttr, matches: xmlValue, nodePtr: node.next, recursive: false)
            }
        }
    }
    
    /// Returns the first descendant node with the specifed attribute name and the value contains the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The first found descendant node or nil if no node matches the parameters.
    
    func descendant(withAttribute attribute : String, contains value : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlAttr, contains: xmlValue, nodePtr: node.children, recursive: true)
            }
        }
    }
    
    /// Returns the first child node with the specifed attribute name and the value contains the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The first found child node or nil if no node matches the parameters.
    
    func child(withAttribute attribute : String, contains value : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlAttr, contains: xmlValue, nodePtr: node.children, recursive: false)
            }
        }
    }
    
    /// Returns the first sibling node with the specifed attribute name and the value contains the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The first found sibling node or nil if no node matches the parameters.
    
    func sibling(withAttribute attribute : String, contains value : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlAttr, contains: xmlValue, nodePtr: node.next, recursive: false)
            }
        }
    }
    
    /// Returns the first descendant node with the specifed attribute name and value begins with the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The value of the attribute.
    /// - Returns: The first found descendant node or nil if no node matches the parameters.
    
    
    func descendant(withAttribute attribute : String, beginsWith value : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlAttr, beginsWith: xmlValue, nodePtr: node.children, recursive: true)
            }
        }
    }
    
    /// Returns the first child node with the specifed attribute name and value begins with the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The value of the attribute.
    /// - Returns: The first found child node or nil if no node matches the parameters.
    
    func child(withAttribute attribute : String, beginsWith value : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlAttr, beginsWith: xmlValue, nodePtr: node.children, recursive: false)
            }
        }
    }
    
    /// Returns the first sibling node with the specifed attribute name and the value begins with the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The first found sibling node or nil if no node matches the parameters.
    
    func sibling(withAttribute attribute : String, beginsWith value : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlAttr, beginsWith: xmlValue, nodePtr: node.next, recursive: false)
            }
        }
    }
    
    /// Returns the first descendant node with the specifed attribute name and value ends with the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The value of the attribute.
    /// - Returns: The first found descendant node or nil if no node matches the parameters.
    
    
    func descendant(withAttribute attribute : String, endsWith value : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlAttr, endsWith: xmlValue, nodePtr: node.children, recursive: true)
            }
        }
    }
    
    /// Returns the first child node with the specifed attribute name and value ends with the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The value of the attribute.
    /// - Returns: The first found child node or nil if no node matches the parameters.
    
    func child(withAttribute attribute : String, endsWith value : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlAttr, endsWith: xmlValue, nodePtr: node.children, recursive: false)
            }
        }
    }
    
    /// Returns the first sibling node with the specifed attribute name and the value ends with the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The first found sibling node or nil if no node matches the parameters.
    
    func sibling(withAttribute attribute : String, endsWith value : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlAttr, endsWith: xmlValue, nodePtr: node.next, recursive: false)
            }
        }
    }
    
    /// Returns all descendant nodes with the specifed attribute name and value matching exactly.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The value of the attribute.
    /// - Returns: The array of all found descendant nodes or an empty array.
    
    func descendants(withAttribute attribute : String, matches value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                children(withAttribute: xmlAttr, matches: xmlValue, nodePtr: node.children, array: &array, recursive: true)
            }
        }
        return array
    }
    
    /// Returns all child nodes with the specifed attribute name and value matching exactly.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The value of the attribute.
    /// - Returns: The array of all found child nodes or an empty array.
    
    func children(withAttribute attribute : String, matches value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                children(withAttribute: xmlAttr, matches: xmlValue, nodePtr: node.children, array: &array, recursive: false)
            }
        }
        return array
    }
    
    /// Returns all sibling nodes with the specifed attribute name and value matching exactly.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The value of the attribute.
    /// - Returns: The array of all found sibling nodes or an empty array.
    
    func siblings(withAttribute attribute : String, matches value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                children(withAttribute: xmlAttr, matches: xmlValue, nodePtr: node.next, array: &array, recursive: false)
            }
        }
        return array
    }
    
    /// Returns all descendant nodes with the specifed attribute name and the value contains the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The array of all found descendant nodes or an empty array.
    
    func descendants(withAttribute attribute : String, contains value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                children(withAttribute: xmlAttr, contains: xmlValue, nodePtr: node.children, array: &array, recursive: true)
            }
        }
        return array
    }
    
    /// Returns all child nodes with the specifed attribute name and the value contains the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The array of all found child nodes or an empty array.
    
    func children(withAttribute attribute : String, contains value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                children(withAttribute: xmlAttr, contains: xmlValue, nodePtr: node.children, array: &array, recursive: false)
            }
        }
        return array
    }
    
    /// Returns all sibling nodes with the specifed attribute name and the value contains the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The array of all found sibling nodes or an empty array.
    
    func siblings(withAttribute attribute : String, contains value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                children(withAttribute: xmlAttr, contains: xmlValue, nodePtr: node.next, array: &array, recursive: false)
            }
        }
        return array
    }
    
    /// Returns all descendant nodes with the specifed attribute name and the value begins with the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The array of all found descendant nodes or an empty array.
    
    func descendants(withAttribute attribute : String, beginsWith value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                children(withAttribute: xmlAttr, beginsWith: xmlValue, nodePtr: node.children, array: &array, recursive: true)
            }
        }
        return array
    }
    
    /// Returns all child nodes with the specifed attribute name and the value begins with the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The array of all found child nodes or an empty array.
    
    func children(withAttribute attribute : String, beginsWith value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                children(withAttribute: xmlAttr, beginsWith: xmlValue, nodePtr: node.children, array:&array, recursive: false)
            }
        }
        return array
    }
    
    /// Returns all sibling nodes with the specifed attribute name and the value begins with the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute
    ///   - value: The partial string of the attribute value
    /// - Returns: The array of all found sibling nodes or an empty array
    
    func siblings(withAttribute attribute : String, beginsWith value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                children(withAttribute: xmlAttr, beginsWith: xmlValue, nodePtr: node.next, array:&array, recursive: false)
            }
        }
        return array
    }
    
    /// Returns all descendant nodes with the specifed attribute name and the value ends with the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The array of all found descendant nodes or an empty array.
    
    func descendants(withAttribute attribute : String, endsWith value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                children(withAttribute: xmlAttr, endsWith: xmlValue, nodePtr: node.children, array:&array, recursive: true)
            }
        }
        return array
    }
    
    /// Returns all child nodes with the specifed attribute name and the value ends with the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The array of all found child nodes or an empty array.
    
    func children(withAttribute attribute : String, endsWith value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                children(withAttribute: xmlAttr, endsWith: xmlValue, nodePtr: node.children, array:&array, recursive: false)
            }
        }
        return array
    }
    
    /// Returns all sibling nodes with the specifed attribute name and the value ends with the specified attribute value.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The array of all found sibling nodes or an empty array.
    
    func siblings(withAttribute attribute : String, endsWith value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            value.withXmlChar { xmlValue in
                children(withAttribute: xmlAttr, endsWith: xmlValue, nodePtr: node.next, array:&array, recursive: false)
            }
        }
        return array
    }
    
    /// Returns the first descendant node with the specifed attribute name.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    /// - Returns: The first found descendant node or nil.
    
    func descendant(withAttribute attribute : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            return child(withAttribute: xmlAttr, nodePtr: node.children, recursive: true)
        }
    }
    
    /// Returns the first child node with the specifed attribute name.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    /// - Returns: The first found child node or nil.
    
    func child(withAttribute attribute : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            return child(withAttribute: xmlAttr, nodePtr: node.children, recursive: false)
        }
    }
    
    /// Returns the first sibling node with the specifed attribute name.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    /// - Returns: The first found sibling node or nil.
    
    func sibling(withAttribute attribute : String) -> HTMLNode?
    {
        return attribute.withXmlChar { xmlAttr in
            return child(withAttribute: xmlAttr, nodePtr: node.next, recursive: false)
        }
    }
    
    /// Returns all descendant nodes with the specifed attribute name.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    /// - Returns: The array of all found descendant nodes or an empty array.
    
    func descendants(withAttribute attribute : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            children(withAttribute: xmlAttr, nodePtr: node.children, array:&array, recursive: true)
        }
        return array
    }
    
    /// Returns all child nodes with the specifed attribute name.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    /// - Returns: The array of all found child nodes or an empty array.
    
    func children(withAttribute attribute : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            children(withAttribute: xmlAttr, nodePtr: node.children, array:&array, recursive: false)
        }
        return array
    }
    
    /// Returns all sibling nodes with the specifed attribute name.
    /// - Parameters:
    ///   - attributeName: The name of the attribute.
    /// - Returns: The array of all found sibling nodes or an empty array.
    
    func siblings(withAttribute attribute : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        attribute.withXmlChar { xmlAttr in
            children(withAttribute: xmlAttr, nodePtr: node.next, array:&array, recursive: false)
        }
        return array
    }
    
    /// Returns the first descendant node with the specifed class value.
    /// - Parameters:
    ///   - value: The name of the class.
    /// - Returns: The first found descendant node or nil.
    
    func descendant(withClass value : String) -> HTMLNode?
    {
        return kClassKey.withXmlChar { xmlClass in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlClass, matches: xmlValue, nodePtr: node.children, recursive: true)
            }
        }
    }
    
    /// Returns the first child node with the specifed class value.
    /// - Parameters:
    ///   - value: The name of the class.
    /// - Returns: The first found child node or nil.
    
    func child(withClass value : String) -> HTMLNode?
    {
        return kClassKey.withXmlChar { xmlClass in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlClass, matches: xmlValue, nodePtr: node.children, recursive: false)
            }
        }
    }
    
    /// Returns the first sibling node with the specifed class value.
    /// - Parameters:
    ///   - value: The name of the class.
    /// - Returns: The first found sibling node or nil.
    
    func sibling(withClass value : String) -> HTMLNode?
    {
        return kClassKey.withXmlChar { xmlClass in
            value.withXmlChar { xmlValue in
                return child(withAttribute: xmlClass, matches: xmlValue, nodePtr: node.next, recursive: false)
            }
        }
    }
    
    /// Returns all descendant nodes with the specifed class value.
    /// - Parameters:
    ///   - value: The name of the class.
    /// - Returns: The array of all found descendant nodes or an empty array.
    
    func descendants(withClass value : String) -> [HTMLNode]
    {
        return self.descendants(withAttribute: kClassKey, matches: value)
    }
    
    /// Returns all child nodes with the specifed class value.
    /// - Parameters:
    ///   - value: The name of the class.
    /// - Returns: The array of all found child nodes or an empty array.
    
    func children(withClass value : String) -> [HTMLNode]
    {
        return self.children(withAttribute: kClassKey, matches: value)
    }
    
    /// Returns all sibling nodes with the specifed class value.
    /// - Parameters:
    ///   - value: The name of the class.
    /// - Returns: The array of all found sibling nodes or an empty array.
    
    func siblings(withClass value : String) -> [HTMLNode]
    {
        return self.siblings(withAttribute: kClassKey, matches: value)
    }
    
    /// Returns the first descendant node with the specifed id value.
    /// - Parameters:
    ///   - value: The name of the class.
    /// - Returns: The first found descendant node or nil.
    
    func descendant(withID value : String) -> HTMLNode?
    {
        return kIDKey.withXmlChar { xmlID in
            value.withXmlChar { xmlValue in
               return child(withAttribute: xmlID, matches: xmlValue, nodePtr: node.children, recursive: true)
            }
        }
    }
    
    /// Returns the first child node with the specifed id value.
    /// - Parameters:
    ///   - value: The name of the class.
    /// - Returns: The first found child node or nil.
    
    func child(withID value : String) -> HTMLNode?
    {
        return kIDKey.withXmlChar { xmlID in
            value.withXmlChar { xmlValue in
               return child(withAttribute: xmlID, matches: xmlValue, nodePtr: node.children, recursive: false)
            }
        }
    }
    
    /// Returns the first sibling node with the specifed id value.
    /// - Parameters:
    ///   - value: The name of the class.
    /// - Returns: The first found sibling node or nil.
    
    func sibling(withID value : String) -> HTMLNode?
    {
        return kIDKey.withXmlChar { xmlID in
            value.withXmlChar { xmlValue in
               return child(withAttribute: xmlID, matches: xmlValue, nodePtr: node.next, recursive: false)
            }
        }
    }
    
    
    private func child(ofTag tag : UnsafePointer<xmlChar>,
                       matches value : UnsafePointer<xmlChar>,
                       nodePtr : xmlNodePtr,
                       recursive : Bool) -> HTMLNode?
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            if xmlStrEqual(currentNodePtr.pointee.name, tag) == 1 {
                let childNodePtr = currentNodePtr.pointee.children
                let childContent = (childNodePtr != nil) ? childNodePtr!.pointee.content : nil
                if childContent != nil && xmlStrEqual(childContent, value) == 1 {
                    return HTMLNode(pointer: currentNodePtr)
                }
            }
            if recursive, let children = currentNodePtr.pointee.children,
                let subNode = child(ofTag: tag, matches: value, nodePtr: children, recursive:recursive) {
                return subNode
            }
        }
        return nil
    }
    
    private func child(ofTag tag : UnsafePointer<xmlChar>,
                       contains value : UnsafePointer<xmlChar>,
                       nodePtr : xmlNodePtr,
                       recursive : Bool) -> HTMLNode?
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            if xmlStrEqual(currentNodePtr.pointee.name, tag) == 1 {
                let childNodePtr = currentNodePtr.pointee.children
                let childContent = (childNodePtr != nil) ? childNodePtr!.pointee.content : nil
                if childContent != nil  && xmlStrstr(childContent, value) != nil {
                    return HTMLNode(pointer: currentNodePtr)
                }
            }
            if recursive, let children = currentNodePtr.pointee.children,
                let subNode = child(ofTag: tag, contains: value, nodePtr: children, recursive:recursive) {
                return subNode
            }
        }
        return nil
    }
    
    /// Returns the first descendant node with the specifed tag name and string value matching exactly.
    /// - Parameters:
    ///   - tag: The name of the tag.
    ///   - value: The string value of the tag.
    /// - Returns: The first found descendant node or nil if no node matches the parameters.
    
    func descendant(ofTag tag : String, matches value : String) -> HTMLNode?
    {
        return tag.withXmlChar { xmlTag in
            value.withXmlChar { xmlValue in
               return child(ofTag: xmlTag, matches: xmlValue,  nodePtr: node.children, recursive: true)
            }
        }
    }
    
    /// Returns the first child node with the specifed tag name and string value matching exactly.
    /// - Parameters:
    ///   - tag: The name of the tag.
    ///   - value: The string value of the tag.
    /// - Returns: The first found child node or nil if no node matches the parameters.
    
    func child(ofTag tag : String, matches value : String) -> HTMLNode?
    {
        return tag.withXmlChar { xmlTag in
            value.withXmlChar { xmlValue in
                return child(ofTag: xmlTag, matches: xmlValue, nodePtr: node.children, recursive: false)
            }
        }
    }
    
    /// Returns the first sibling node with the specifed tag name and string value matching exactly.
    /// - Parameters:
    ///   - tag: The name of the tag.
    ///   - value: The string value of the tag.
    /// - Returns: The first found sibling node or nil if no node matches the parameters.
    
    func sibling(ofTag tag : String, matches value : String) -> HTMLNode?
    {
        return tag.withXmlChar { xmlTag in
            value.withXmlChar { xmlValue in
                return child(ofTag: xmlTag, matches: xmlValue, nodePtr: node.next, recursive: false)
            }
        }
    }
    
    /// Returns the first descendant node with the specifed attribute name and the string value contains the specified value.
    /// - Parameters:
    ///   - tag: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The first found descendant node or nil if no node matches the parameters.
    
    func descendant(ofTag tag : String, contains value : String) -> HTMLNode?
    {
        return tag.withXmlChar { xmlTag in
            value.withXmlChar { xmlValue in
                return child(ofTag: xmlTag, contains: xmlValue, nodePtr: node.children, recursive: true)
            }
        }
    }
    
    /// Returns the child node with the specifed attribute name and the string value contains the specified value.
    /// - Parameters:
    ///   - tag: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The first found child node or nil if no node matches the parameters.
    
    func child(ofTag tag : String, contains value : String) -> HTMLNode?
    {
        return tag.withXmlChar { xmlTag in
            value.withXmlChar { xmlValue in
                return child(ofTag: xmlTag, contains: xmlValue, nodePtr: node.children, recursive: false)
            }
        }
    }
    
    /// Returns the sibling node with the specifed attribute name and the string value contains the specified value.
    /// - Parameters:
    ///   - tag: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The first found sibling node or nil if no node matches the parameters.
    
    func sibling(ofTag tag : String, contains value : String) -> HTMLNode?
    {
        return tag.withXmlChar { xmlTag in
            value.withXmlChar { xmlValue in
                return child(ofTag: xmlTag, contains: xmlValue, nodePtr:node.next, recursive: false)
            }
        }
    }
    
    
    private func children(ofTag tag : UnsafePointer<xmlChar>,
                          matches value : UnsafePointer<xmlChar>,
                          nodePtr : xmlNodePtr,
                          array : inout [HTMLNode],
                          recursive : Bool)
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            if xmlStrEqual(currentNodePtr.pointee.name, tag) == 1 {
                if xmlStrEqual(currentNodePtr.pointee.children.pointee.content, value) == 1 {
                    if let matchingNode = HTMLNode(pointer: currentNodePtr) {
                        array.append(matchingNode)
                    }
                }
            }
            if recursive, let childrn = currentNodePtr.pointee.children {
                children(ofTag:tag, matches: value, nodePtr: childrn, array: &array, recursive: recursive)
            }
        }
    }
    
    private func children(ofTag tag : UnsafePointer<xmlChar>,
                          contains value : UnsafePointer<xmlChar>,
                          nodePtr : xmlNodePtr,
                          array : inout [HTMLNode],
                          recursive : Bool)
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            if xmlStrEqual(currentNodePtr.pointee.name, tag) == 1 {
                
                if xmlStrstr(currentNodePtr.pointee.children.pointee.content, value) != nil {
                    if let matchingNode = HTMLNode(pointer: currentNodePtr) {
                        array.append(matchingNode)
                    }
                }
            }
            if recursive, let childrn = currentNodePtr.pointee.children {
                children(ofTag: tag, contains: value, nodePtr: childrn, array: &array, recursive: recursive)
            }
        }
    }
    
    /// Returns all descendant nodes with the specifed tag name and string value matching exactly.
    /// - Parameters:
    ///   - tag: The name of the tag.
    ///   - value: The string value of the tag.
    /// - Returns: The array of all found descendant nodes or an empty array.
    
    func descendants(ofTag tag : String, matches value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        tag.withXmlChar { xmlTag in
            value.withXmlChar { xmlValue in
                children(ofTag: xmlTag, matches: xmlValue, nodePtr:node.children, array: &array, recursive: true)
            }
        }
        return array
    }
    
    /// Returns all child nodes with the specifed tag name and string value matching exactly.
    /// - Parameters:
    ///   - tag: The name of the tag.
    ///   - value: The string value of the tag.
    /// - Returns: The array of all found child nodes or an empty array.
    
    func children(ofTag tag : String, matches value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        tag.withXmlChar { xmlTag in
            value.withXmlChar { xmlValue in
                 children(ofTag: xmlTag, matches: xmlValue, nodePtr:node.children, array: &array, recursive: false)
            }
        }
        return array
    }
    
    /// Returns all sibling nodes with the specifed tag name and string value matching exactly.
    /// - Parameters:
    ///   - tag: The name of the tag.
    ///   - value: The string value of the tag.
    /// - Returns: The array of all found sibling nodes or an empty array.
    
    func siblings(ofTag tag : String, matches value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        tag.withXmlChar { xmlTag in
            value.withXmlChar { xmlValue in
                children(ofTag: xmlTag, matches: xmlValue, nodePtr:node.next, array: &array, recursive: false)
            }
        }
        return array
    }
    
    /// Returns all descendant nodes with the specifed attribute name and the string value contains the specified value.
    /// - Parameters:
    ///   - tag: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The array of all found descendant nodes or an empty array.
    
    func descendants(ofTag tag : String, contains value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        tag.withXmlChar { xmlTag in
            value.withXmlChar { xmlValue in
                children(ofTag: xmlTag, contains: xmlValue,  nodePtr:node.children, array: &array, recursive: true)
            }
        }
        return array
    }
    
    /// Returns all child nodes with the specifed attribute name and the string value contains the specified value.
    /// - Parameters:
    ///   - tag: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The array of all found child nodes or an empty array.
    
    func children(ofTag tag : String, contains value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        tag.withXmlChar { xmlTag in
            value.withXmlChar { xmlValue in
                 children(ofTag:xmlTag, contains: xmlValue,  nodePtr:node.children, array: &array, recursive: false)
            }
        }
        return array
    }
    
    /// Returns all sibling nodes with the specifed attribute name and the string value contains the specified value.
    /// - Parameters:
    ///   - tag: The name of the attribute.
    ///   - value: The partial string of the attribute value.
    /// - Returns: The array of all found sibling nodes or an empty array.
    
    func siblings(ofTag tag : String, contains value : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        tag.withXmlChar { xmlTag in
            value.withXmlChar { xmlValue in
                children(ofTag: xmlTag, contains: xmlValue,  nodePtr:node.next, array: &array, recursive: false)
            }
        }
        return array
    }
    
    
    
    private func child(ofTag tag : UnsafePointer<xmlChar>,
                       nodePtr : xmlNodePtr,
                       recursive : Bool)  -> HTMLNode?
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            let currentNode = currentNodePtr.pointee
            if currentNode.name != nil &&  xmlStrEqual(currentNode.name, tag) == 1 {
                return HTMLNode(pointer:currentNodePtr)
            }
            if recursive, let children = currentNodePtr.pointee.children,
                let subNode = child(ofTag: tag, nodePtr:children, recursive:recursive) {
                return subNode
            }
        }
        return nil
    }
    
    /// Returns the first descendant node with the specifed tag name.
    /// - Parameters:
    ///   - tag: The name of the tag.
    /// - Returns: The first found descendant node or nil.
    
    func descendant(ofTag tag : String) -> HTMLNode?
    {
        return tag.withXmlChar { xmlTag in
            return child(ofTag: xmlTag, nodePtr: node.children, recursive: true)
        }
    }
    
    /// Returns the first child node with the specifed tag name.
    /// - Parameters:
    ///   - tag: The name of the tag.
    /// - Returns: The first found child node or nil.
    
    func child(ofTag tag : String) -> HTMLNode?
    {
        return tag.withXmlChar { xmlTag in
            return child(ofTag: xmlTag, nodePtr: node.children, recursive: false)
        }
    }
    
    /// Returns the first sibling node with the specifed tag name.
    /// - Parameters:
    ///   - tag: The name of the tag.
    /// - Returns: The first found sibling node or nil.
    
    func sibling(ofTag tag : String) -> HTMLNode?
    {
        return tag.withXmlChar { xmlTag in
                return child(ofTag: xmlTag, nodePtr: node.next, recursive: false)
        }
    }
    
    private func children(ofTag tag : UnsafePointer<xmlChar>,
                          nodePtr : xmlNodePtr,
                          array : inout [HTMLNode],
                          recursive : Bool)
    {
        for currentNodePtr in XmlNodeSequence(node: nodePtr) {
            let currentNode = currentNodePtr.pointee
            if currentNode.name != nil &&  xmlStrEqual(currentNode.name, tag) == 1 {
                if let matchingNode = HTMLNode(pointer: currentNodePtr) {
                    array.append(matchingNode)
                }
            }
            
            if recursive, let childrn = currentNodePtr.pointee.children {
                children(ofTag: tag, nodePtr: childrn, array: &array, recursive: recursive)
            }
        }
    }
    
    /// Returns all descendant nodes with the specifed tag name.
    /// - Parameters:
    ///   - tag: The name of the tag.
    /// - Returns: The array of all found descendant nodes or an empty array.
    
    func descendants(ofTag tag : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        tag.withXmlChar { xmlTag in
            children(ofTag: xmlTag, nodePtr: node.children, array: &array, recursive: true)
        }
        return array
    }
    
    /// Returns all child nodes with the specifed tag name.
    /// - Parameters:
    ///   - tag: The name of the tag.
    /// - Returns: The array of all found child nodes or an empty array.
    
    func children(ofTag tag : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        tag.withXmlChar { xmlTag in
            children(ofTag: xmlTag, nodePtr: node.children, array: &array, recursive: false)
        }
        return array
    }
    
    /// Returns all sibling nodes with the specifed tag name.
    /// - Parameters:
    ///   - tag: The name of the tag.
    /// - Returns: The array of all found sibling nodes or an empty array.
    
    func siblings(ofTag tag : String) -> [HTMLNode]
    {
        var array = [HTMLNode]()
        tag.withXmlChar { xmlTag in
            children(ofTag: xmlTag, nodePtr: node.next, array:&array, recursive: false)
        }
        return array
    }
    
    // MARK: mark - description
    
    // includes type, tag , number of children, attributes and the raw content
    var description : String {
        return "type: \(elementType) - tag name: \(tagName ?? "n/a") - number of children: \(childCount)\nattributes: \(attributes.description)\nHTML: \(HTMLString ?? "n/a")"
    }
    
    // creates a String from a xmlChar pointer
    
    func stringFrom(xmlchar: UnsafePointer<xmlChar>) -> String {
        return String.decodeCString(xmlchar, as: UTF8.self, repairingInvalidCodeUnits: false)?.result ?? ""
    }
    
    // sequence generator to be able to write "for item in HTMLNode" as a shortcut for "for item in HTMLNode.children"
    
    func makeIterator() -> HTMLNodeIterator {
        return HTMLNodeIterator(node: self)
    }
    
    // MARK: -  Equation protocol
    
    static func == (lhs: HTMLNode, rhs: HTMLNode) -> Bool {
        return xmlXPathCmpNodes(lhs.pointer, rhs.pointer) == 0
    }
}

struct HTMLNodeIterator : IteratorProtocol {
    var node: xmlNodePtr?
    
    init(node: HTMLNode) {
        self.node = node.pointer.pointee.children
    }
    
    mutating func next() -> HTMLNode? {
        if xmlNodeIsText(node) == 1 {
            node = node?.pointee.next
            if node == nil  { return .none }
        }
        let nextNode = HTMLNode(pointer:node)
        node = node?.pointee.next
        return node == nil ?  .none : nextNode
    }
    
}




