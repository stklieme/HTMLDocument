/*###################################################################################
 #                                                                                   #
 #    HTMLNode+XPath.swift - Extension for HTMLNode                                  #
 #                                                                                   #
 #    Copyright © 2014-2017 by Stefan Klieme                                         #
 #                                                                                   #
 #    Swift wrapper for HTML parser of libxml2                                       #
 #                                                                                   #
 #    Version 1.0.1 - 4. Sep 2017                                                    #
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

enum XPathError: Error {
    case evaluationFailed(Int32, String)
    case contextFailed
}

extension HTMLNode  {
    
    // XPath format predicates
    
    struct XPathPredicate {
        static var node: (String) -> String = { return "./descendant::\($0)" }
        static var nodeWith: (String, String) -> String = { return "//\($0)[@\($1)]" }
        static var attribute: (String) -> String = { return "//*[@\($0)]" }
        static var attributeIsEqual: (String, String) -> String = { return "//*[@\($0) ='\($1)']" }
        static var attributeBeginsWith: (String, String) -> String = { return "./*[starts-with(@\($0),'\($1)')]" }
        static var attributeEndsWith: (String, String) -> String = { return "//*['\($1)' = substring(@\($0)@, string-length(@\($0))- string-length('\($1)') +1)]" }
        static var attributeContains: (String, String) -> String = { return "//*[contains(@\($0),'\($1)')]" }
    }
    
    // performXPathQuery() Returns an array of HTMLNode objects if the query matches any nodes, otherwise an empty array
    
    private func performXPathQuery(node : xmlNodePtr, query : String, returnSingleNode : Bool) throws -> [HTMLNode]
    {
        let xmlDoc = node.pointee.doc
        let xpathContext = xmlXPathNewContext(xmlDoc)
        
        guard xpathContext != nil else { throw XPathError.contextFailed }
        defer { xmlXPathFreeContext(xpathContext!) }
        
        let xpathErrorCallBack : xmlStructuredErrorFunc = { (context, errorPtr) in
            let node = Unmanaged<HTMLNode>.fromOpaque(context!).takeUnretainedValue()
            let error = errorPtr!.pointee
            let message = error.message!
            node.xpathErrorCode = error.code
            node.xpathErrorMessage = String(validatingUTF8: message)!.trimmingCharacters(in: CharacterSet.newlines)
        }
        
        xmlSetStructuredErrorFunc(UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), xpathErrorCallBack)
        
        defer { xmlSetStructuredErrorFunc(nil, nil) }
        
        let xpathObject = query.withXmlChar { xmlQuery -> xmlXPathObjectPtr! in
            if (query.hasPrefix("//") || query.hasPrefix("./")) {
                return xmlXPathNodeEval(node, xmlQuery, xpathContext)
            } else {
                return xmlXPathEvalExpression(xmlQuery, xpathContext)
            }
        }
        
        guard xpathObject != nil else { throw XPathError.evaluationFailed(xpathErrorCode, xpathErrorMessage) }
        defer { xmlXPathFreeObject(xpathObject) }
        
        if let nodes = xpathObject!.pointee.nodesetval, nodes.pointee.nodeNr > 0, nodes.pointee.nodeTab != nil {
            let nodesArray = UnsafeBufferPointer(start: nodes.pointee.nodeTab, count: Int(nodes.pointee.nodeNr))
            if returnSingleNode {
                if let node = HTMLNode(pointer:nodesArray[0]) {
                    return [node]
                }
            } else {
                return nodesArray.flatMap{ HTMLNode(pointer:$0) }
            }
        }
        return [HTMLNode]()
    }
    
    
    // MARK: - Objective-C wrapper for XPath Query function
    
    /// Returns the first descendant node for a XPath query.
    /// - Parameters:
    ///   - query: The XPath query string.
    /// - Returns:  The first found descendant node or nil if no node matches the parameters.
    
    func node(forXPath query : String) throws -> HTMLNode?
    {
        return try performXPathQuery(node: pointer, query: query, returnSingleNode: true).first
    }
    
    /// Returns all descendant nodes for a XPath query.
    /// - Parameters:
    ///   - query: The XPath query string.
    /// - Returns:  The array of all found descendant nodes or an empty array.
    
    func nodes(forXPath query : String) throws -> [HTMLNode]
    {
        return try performXPathQuery(node: pointer, query: query, returnSingleNode: false)
    }
    
    // MARK: - specific XPath Query methods
    // Note: In the HTMLNode main class all appropriate query methods begin with descendant instead of node
    
    /// Returns the first descendant node for a matching tag name and matching attribute name.
    /// - Parameters:
    ///   - tag: The tag name.
    ///   - attribute: The attribute name (optional, default is no attribute).
    /// - Returns:  The first found descendant node or nil if no node matches the parameters.
    
    func node(ofTag tag : String, with attribute : String = "") throws -> HTMLNode?
    {
        let predicate = attribute.isEmpty ? XPathPredicate.node(tag) : XPathPredicate.nodeWith(tag, attribute)
        return try node(forXPath: predicate)
    }
    
    /// Returns all descendant nodes for a matching tag name and matching attribute name.
    /// - Parameters:
    ///   - tag: The tag name.
    ///   - attribute: The attribute name (optional, default is no attribute).
    /// - Returns:  The array of all found descendant nodes or an empty array.
    
    func nodes(ofTag tag : String, with attribute : String = "") throws -> [HTMLNode]
    {
        let predicate = attribute.isEmpty ? XPathPredicate.node(tag) : XPathPredicate.nodeWith(tag, attribute)
        return try nodes(forXPath: predicate)
    }
    
    /// Returns the first descendant node for a specified attribute name.
    /// - Parameters:
    ///   - attribute: The attribute name.
    /// - Returns:  The first found descendant node or nil if no node matches the parameters.
    
    func node(withAttribute attribute : String) throws -> HTMLNode?
    {
        return try node(forXPath: XPathPredicate.attribute(attribute))
    }
    
    /// Returns all descendant nodes for a specified attribute name.
    /// - Parameters:
    ///   - attribute: The attribute name.
    /// - Returns:  The array of all found descendant nodes or an empty array.
    
    func nodes(withAttribute attribute : String) throws -> [HTMLNode]
    {
        return try nodes(forXPath: XPathPredicate.attribute(attribute))
    }
    
    /// Returns the first descendant node for a matching attribute name and matching attribute value.
    /// - Parameters:
    ///   - attribute: The attribute name.
    ///   - value: The attribute value.
    /// - Returns:  The first found descendant node or nil if no node matches the parameters.
    
    func node(withAttribute attribute : String, matches value : String) throws -> HTMLNode?
    {
        return try node(forXPath: XPathPredicate.attributeIsEqual(attribute, value))
    }
    
    /// Returns all descendant nodes for a matching attribute name and matching attribute value.
    /// - Parameters:
    ///   - attribute: The attribute name.
    ///   - value: The attribute value.
    /// - Returns:  The array of all found descendant nodes or an empty array.
    
    func nodes(withAttribute attribute : String, matches value : String) throws -> [HTMLNode]
    {
        return try nodes(forXPath: XPathPredicate.attributeIsEqual(attribute, value))
    }
    
    /// Returns the first descendant node for a matching attribute name and beginning of the attribute value.
    /// - Parameters:
    ///   - attribute: The attribute name.
    ///   - value: The attribute value.
    /// - Returns:  The first found descendant node or nil if no node matches the parameters.
    
    func node(withAttribute attribute : String, beginsWith value : String) throws -> HTMLNode?
    {
        return try node(forXPath: XPathPredicate.attributeBeginsWith(attribute, value))
    }
    
    /// Returns all descendant nodes for a matching attribute name and beginning of the attribute value.
    /// - Parameters:
    ///   - attribute: The attribute name.
    ///   - value: The attribute value.
    /// - Returns:  The array of all found descendant nodes or an empty array.
    
    func nodes(withAttribute attribute : String, beginsWith value : String) throws -> [HTMLNode]
    {
        return try nodes(forXPath: XPathPredicate.attributeBeginsWith(attribute, value))
    }
    
    /// Returns the first descendant node for a matching attribute name and ending of the attribute value.
    /// - Parameters:
    ///   - attribute: The attribute name.
    ///   - value: The attribute value.
    /// - Returns:  The first found descendant node or nil if no node matches the parameters.
    
    func node(withAttribute attribute : String, endsWith value : String) throws -> HTMLNode?
    {
        return try node(forXPath: XPathPredicate.attributeEndsWith(attribute, value))
    }
    
    /// Returns all descendant nodes for a matching attribute name and ending of the attribute value.
    /// - Parameters:
    ///   - attribute: The attribute name.
    ///   - value: The attribute value.
    /// - Returns:  The array of all found descendant nodes or an empty array.
    
    func nodes(withAttribute attribute : String, endsWith value : String) throws -> [HTMLNode]
    {
        return try nodes(forXPath: XPathPredicate.attributeEndsWith(attribute, value))
    }
    
    /// Returns the first descendant node for a matching attribute name and containing the attribute value.
    /// - Parameters:
    ///   - attribute: The attribute name.
    ///   - value: The attribute value.
    /// - Returns:  The first found descendant node or nil if no node matches the parameters.
    
    func node(withAttribute attribute : String, contains value : String) throws -> HTMLNode?
    {
        return try node(forXPath: XPathPredicate.attributeContains(attribute, value))
    }
    
    /// Returns all descendant nodes for a matching attribute name and containing the attribute value.
    /// - Parameters:
    ///   - attribute: The attribute name.
    ///   - value: The attribute value.
    /// - Returns:  The array of all found descendant nodes or an empty array.
    
    func nodes(withAttribute attribute : String, contains value : String) throws -> [HTMLNode]
    {
        return try nodes(forXPath: XPathPredicate.attributeContains(attribute, value))
    }
    
    /// Returns the first descendant node for a specified class name.
    /// - Parameters:
    ///   - value The class name.
    /// - Returns:  The first found descendant node or nil if no node matches the parameters.
    
    func node(withClass value : String) throws  -> HTMLNode?
    {
        return try node(withAttribute: AttributeKey.`class`, matches: value)
    }
    
    /// Returns all descendant nodes for a specified class name.
    /// - Parameters:
    ///   - value The class name.
    /// - Returns:  The array of all found descendant nodes or an empty array.
    
    func nodes(withClass value : String) throws -> [HTMLNode]
    {
        return try nodes(withAttribute: AttributeKey.`class`, matches: value)
    }
    
}
