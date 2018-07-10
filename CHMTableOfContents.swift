//
//  CHMTableOfContents.swift
//  Chmox a CHM file viewer for Mac OS X
//
//  Created by C.W. Betts on 2/15/17.
//
//  Chmox is free software; you can redistribute it and/or modify it
//  under the terms of the GNU Lesser General Public License as published
//  by the Free Software Foundation; either version 2.1 of the License, or
//  (at your option) any later version.
//
//  Chmox is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with Foobar; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//

import Cocoa

private struct TOCBuilderContext {
    // Context
    var container: CHMContainer
    var toc: CHMTableOfContents
    var topicStack = [CHMTopic]()
    var placeholder: CHMTopic = CHMTopic()
    var lastTopic: CHMTopic? = nil
    
    // Topic properties
    var name: String? = nil
    var path: String? = nil
    
    init(container: CHMContainer, toc: CHMTableOfContents) {
        self.container = container
        self.toc = toc
    }
}

private func createNewTopic(_ context: UnsafeMutablePointer<TOCBuilderContext>) {
    var location: URL? = nil
    if let path = context.pointee.path {
        location = CHMURLProtocol.url(withPath: path, in: context.pointee.container)
    } else {
        location = CHMURLProtocol.url(withPath: "Help mee...", in: context.pointee.container)
    }
    context.pointee.lastTopic = CHMTopic(name: context.pointee.name!, location: location)
    context.pointee.name = nil
    context.pointee.path = nil
    
    //let level = context.pointee.topicStack.count
    
    // Add topic to its parent
    for parent in context.pointee.topicStack.reversed() {
        if parent !== context.pointee.placeholder {
            parent.addObject(context.pointee.lastTopic!)
            return
        }
    }
    
    context.pointee.toc.addRootTopic(context.pointee.lastTopic)
}

private func documentDidStart(_ context: UnsafeMutableRawPointer?) {
 
}

private func documentDidEnd(_ context: UnsafeMutableRawPointer?) {
    
}

private func elementDidStart(_ context: UnsafeMutableRawPointer?, _ name: UnsafePointer<xmlChar>?, _ atts: UnsafeMutablePointer<UnsafePointer<xmlChar>?>?) {
    guard let name = UnsafeRawPointer(name)?.assumingMemoryBound(to: Int8.self),
        let context = context?.assumingMemoryBound(to: TOCBuilderContext.self) else {
        return
    }
    //DEBUG_OUTPUT( @"SAX:elementDidStart %s", name );
    
    if strcasecmp( "ul", name) == 0 {
        //DEBUG_OUTPUT( @"Stack BEFORE %@", context->topicStack );
        
        if context.pointee.name != nil {
            createNewTopic(context)
        }
        
        if let lastTopic = context.pointee.lastTopic {
            context.pointee.topicStack.append(lastTopic)
            context.pointee.lastTopic = nil
        } else {
            context.pointee.topicStack.append(context.pointee.placeholder)
        }
        
        //DEBUG_OUTPUT( @"Stack AFTER %@", context->topicStack );
    } else if strcasecmp("li", name) == 0 {
        // Opening depth level
        context.pointee.name = nil;
        context.pointee.path = nil;
    } else if strcasecmp("param", name) == 0, let atts = atts  {
        // Topic properties
        var type: UnsafePointer<xmlChar>? = nil
        var value: UnsafePointer<xmlChar>? = nil
        
        var i = 0
        while atts[i] != nil {
            let attr = UnsafeRawPointer(atts[i]!).assumingMemoryBound(to: Int8.self)
            if strcasecmp("name", attr) == 0 {
                type = atts[ i + 1 ];
            } else if strcasecmp("value", attr) == 0 {
                value = atts[i + 1];
            }

            i += 2
        }
        
        if let type = UnsafeRawPointer(type)?.assumingMemoryBound(to: Int8.self),
            let value = UnsafeRawPointer(value)?.assumingMemoryBound(to: Int8.self) {
            if strcasecmp("Name", type) == 0 {
                // Name of the topic
                context.pointee.name = String(cString: value)
            } else if strcasecmp("Local", type) == 0 {
                // Path of the topic
                context.pointee.path = String(cString: value)
            } else {
                // Unsupported topic property
                //NSLog( @"type=%s  value=%s", type, value );
            }
        }
    }
}

private func elementDidEnd(_ context: UnsafeMutableRawPointer?, _ name: UnsafePointer<xmlChar>?) {
    guard let name = UnsafeRawPointer(name)?.assumingMemoryBound(to: Int8.self), let context = context?.assumingMemoryBound(to: TOCBuilderContext.self) else {
        return
    }
    //DEBUG_OUTPUT( @"SAX:elementDidEnd %s", name );
    
    if strcasecmp("li", name) == 0 && context.pointee.name != nil {
        // New complete topic
        createNewTopic( context );
    } else if strcasecmp("ul", name) == 0 {
        //DEBUG_OUTPUT( @"Stack BEFORE %@", context->topicStack );
        
        // Closing depth level
        if context.pointee.topicStack.count > 0 {
            context.pointee.lastTopic = context.pointee.topicStack.removeLast()
            
            if context.pointee.lastTopic === context.pointee.placeholder {
                context.pointee.lastTopic = nil;
            }
        } else {
            context.pointee.lastTopic = nil;
        }
        
        //DEBUG_OUTPUT( @"Stack AFTER %@", context->topicStack );
    }
}

private var saxHandler: htmlSAXHandler = {
    var aHandler = htmlSAXHandler()
    aHandler.startDocument = documentDidStart
    aHandler.endDocument = documentDidEnd
    aHandler.startElement = elementDidStart
    aHandler.endElement = elementDidEnd
    
    return aHandler
}()

class CHMTableOfContents: NSObject {
    @objc fileprivate(set) var rootTopics = [CHMTopic]()
    
    @objc init(container: CHMContainer) {
        super.init()
        
        guard let tocData = container.dataWithTableOfContents else {
            return
        }
        
        var context = TOCBuilderContext(container: container, toc: self)
        
        let parser = tocData.withUnsafeBytes({ (dat: UnsafePointer<Int8>) -> htmlParserCtxtPtr? in
            // XML_CHAR_ENCODING_NONE / XML_CHAR_ENCODING_UTF8 / XML_CHAR_ENCODING_8859_1
            let parser1 = htmlCreatePushParserCtxt(&saxHandler, &context,
												   dat,
												   Int32(tocData.count),
												   nil, XML_CHAR_ENCODING_8859_1)
            htmlParseChunk(parser1, dat, 0, 1)
            return parser1
        })
        
        let doc = parser?.pointee.myDoc
        htmlFreeParserCtxt(parser);
        if let doc = doc {
            xmlFreeDoc(doc);
        }
    }
    
    fileprivate func addRootTopic(_ topic: CHMTopic?) {
        rootTopics.append(topic!)
    }
}

extension CHMTableOfContents: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let anItem = item as? CHMTopic {
            return anItem.countOfSubTopics
        }
        return rootTopics.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let item = item as? CHMTopic {
            return item.countOfSubTopics > 0
        }
        
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let anItem = item as? CHMTopic {
            return anItem.objectInSubTopics(at: index)!
        }
        return rootTopics[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if let anItem = item as? CHMTopic {
            return anItem.name
        }
        return nil
    }
}
