/*###################################################################################
 #                                                                                   #
 #    HTMLDocument.swift                                                             #
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

enum HTMLDocumentError: Error {
    case invalidData
    case dataEmpty
    case notHTML
    case couldNotParse
    case missingRootElement
}

class HTMLDocument {
    
    /// The class name.
    
    var className : String {
        return "HTMLDocument"
    }
    
    /// The document pointer.
    
    let htmlDoc: htmlDocPtr
    
    /// The root node.
    
    let rootNode: HTMLNode
    
    /// The head node.
    
    var head: HTMLNode? {
        return rootNode.child(ofTag:"head")
    }
    
    /// The body node.
    
    var body: HTMLNode? {
        return rootNode.child(ofTag:"body")
    }
    
    /// The value of the title tag in the head node.
    
    var title: String? {
        return head?.child(ofTag:"title")?.stringValue
    }
    
    // MARK: - Initialzers
    
    // default text encoding is UTF-8
    
    /// Initializes and returns an HTMLDocument object created from an Data object with specified string encoding.
    /// - Parameters:
    ///   - data: A data object with HTML content.
    ///   - encoding: The string encoding for the HTML content (optional, default is UTF8).
    /// - Returns: An initialized HTMLDocument object, if initialization fails an error is thrown.
    
    init(data: Data?, encoding: String.Encoding = .utf8) throws // designated initializer
    {
        guard let htmlData = data else { throw HTMLDocumentError.invalidData }
        guard !htmlData.isEmpty else { throw HTMLDocumentError.dataEmpty }
        
        let cfEncoding = CFStringConvertNSStringEncodingToEncoding(encoding.rawValue)
        let cfEncodingAsString = CFStringConvertEncodingToIANACharSetName(cfEncoding)
        let cEncoding = CFStringGetCStringPtr(cfEncodingAsString, 0)
        
        let htmlParseOptions : CInt = 1 << 0 | 1 << 5 | 1 << 6 // HTML_PARSE_RECOVER | HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING
        let cCharacters = htmlData.withUnsafeBytes { (bytes: UnsafePointer<Int8>) -> [CChar] in
            let buffer = UnsafeBufferPointer(start: bytes, count: htmlData.count)
            return [CChar](buffer)
        }
        
        guard let htmlDoc = htmlReadMemory(cCharacters, CInt(htmlData.count), nil, cEncoding, htmlParseOptions) else { throw HTMLDocumentError.couldNotParse }
        guard let xmlDocRootNode = xmlDocGetRootElement(htmlDoc) else { throw HTMLDocumentError.missingRootElement }
        if let docRootNodeName = String.decodeCString(xmlDocRootNode.pointee.name, as: UTF8.self, repairingInvalidCodeUnits: false)?.result,
            docRootNodeName == "html" {
            self.htmlDoc = htmlDoc
            self.rootNode = HTMLNode(pointer: xmlDocRootNode)!
        } else {
            throw HTMLDocumentError.notHTML
        }
    }
    
    /// Initializes and returns an HTMLDocument object created from the HTML contents of a URL-referenced source with specified string encoding.
    /// - Parameters:
    ///   - url: An URL object specifying a URL source.
    ///   - encoding: The string encoding for the HTML content (optional, default is UTF8).
    /// - Returns: An initialized HTMLDocument object, or an error is thrown.
    
    convenience init(contentsOf url: URL, encoding: String.Encoding = .utf8) throws
    {
        let data = try Data(contentsOf: url)
        try self.init(data:data, encoding:encoding)
    }
    
    /// Initializes and returns an HTMLDocument object created from a string containing HTML markup text with specified string encoding.
    /// - Parameters:
    ///   - string: An string conaining the HTML source.
    ///   - encoding: The string encoding for the HTML content (optional, default is UTF8).
    /// - Returns: An initialized HTMLDocument object, or an error is thrown.
    
    
    convenience init(string: String, encoding: String.Encoding = .utf8) throws
    {
        try self.init(data: string.data(using: encoding), encoding:encoding)
    }
}
