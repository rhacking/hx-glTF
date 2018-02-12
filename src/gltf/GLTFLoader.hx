package gltf;

import haxe.io.Bytes;
import haxe.crypto.Base64;

import tink.Json;
import tink.json.Representation;

using Lambda;

typedef GLTF = {
    var asset : Asset;
    
    @:optional var scenes : Array<Scene>;
    @:optional var scene : Int;

    @:optional var nodes : Array<Node>;

    @:optional var buffers : Array<Buffer>;
    @:optional var bufferViews : Array<BufferView>;

    @:optional var accessors : Array<Accessor>;

    @:optional var meshes : Array<Mesh>;

    @:optional var skins : Array<Skin>;
}

typedef Asset = {
    @:optional var minVersion : String;
    var version : String;
    @:optional var generator : String;
    @:optional var copyright : String;
}

typedef Scene = {
    @:optional var name : String;
}

typedef Node = {
    @:optional var name : String;
    @:optional var children : Array<Int>;

    @:optional var matrix : Matrix4;

    @:optional var translation : Vector3;
    @:optional var rotation : Vector4;
    @:optional var scale : Vector3;

    @:optional var mesh : MeshReference;
    @:optional var skin : SkinReference;    
}

typedef Buffer = {
    var byteLength : Int;
    var uri : DataURI;
}

typedef BufferViewRaw = {
    var buffer : Int;
    var byteLength : Int;
    var byteOffset : Int;
    var target : Int;
    @:optional var byteStride : Int;
}

@:jsonParse(gltf.GLTFLoader.BufferViewParser)
typedef BufferView = {
    var buffer : BufferReference;
    var byteLength : Int;
    var byteOffset : Int;
    var target : BufferTarget;
}

typedef Accessor = {
    var bufferView : BufferViewReference;
    var byteOffset : Int;
    var count : Int;
    var type : DataType;
}

typedef Mesh = {
    var primitives : Array<Primitive>;
    @:optional var weights : Array<Float>;
}

typedef Primitive = {
    var attributes : Attributes;
    @:optional var indices : AccessorReference;
    @:optional var material : Int; // TODO: Material reference
    var mode : Int;
    @:optional var targets : Array<Attributes>;
}

typedef Attributes = {
    @:json('POSITION') @:optional var position : AccessorReference;
    @:json('NORMAL') @:optional var normal : AccessorReference;
    @:json('TANGENT') @:optional var tangent : AccessorReference;
    @:json('TEXCOORD_0') @:optional var texcoord_0 : AccessorReference;
    @:json('COLOR_0') @:optional var color_0 : AccessorReference;
    @:json('JOINTS_0') @:optional var joints_0 : AccessorReference;
    @:json('WEIGHTS_0') @:optional var weights_0 : AccessorReference;    
}

typedef Skin = {
    var inverseBindMatrices : AccessorReference;
    var joints : Array<NodeReference>;
    var skeleton : NodeReference;
}

@:enum
abstract ComponentType(Int) {
    var Byte = 5120;
    var UnsignedByte = 5121;
    var Short = 5122;
    var UnsignedShort = 5123;
    var UnsignedInt = 5125;
    var Float = 5126;
}

enum Stride {
    Fixed(v : Int);
    Tight;
}

abstract DataURI(Bytes) to Bytes {
    inline function new(v) this = v;

    @:to function toRepresentation():Representation<String> {
        return new Representation('data:application/octet-stream;base64,${Base64.encode(this)}');
    }

    @:from static function ofRepresentation(rep:Representation<String>) {
        if (DATA_URI_PATTERN.match(rep.get()))
            return new DataURI(Base64.decode(DATA_URI_PATTERN.matched(1)));
        else
            throw 'Only base64-encoded data-uris are currently supported (failed to read ${rep.get()}';
    }
}

abstract AccessorReference(Int) to Int {
    inline function new(v) this = v;

    public inline function get(glTF : GLTF) {
        return glTF.accessors[this];
    }

    @:to function toRepresentation():Representation<Int> 
        return new Representation(this);

    @:from static function ofRepresentation(rep:Representation<Int>)
        return new AccessorReference(rep.get());
}

abstract BufferReference(Int) to Int {
    public inline function new(v) this = v;

    public inline function get(glTF : GLTF) {
        return glTF.buffers[this];
    }

    @:to function toRepresentation():Representation<Int> 
        return new Representation(this);

    @:from static function ofRepresentation(rep:Representation<Int>)
        return new BufferReference(rep.get());
}

abstract BufferViewReference(Int) to Int {
    inline function new(v) this = v;

    public inline function get(glTF : GLTF) {
        return glTF.bufferViews[this];
    }

    @:to function toRepresentation():Representation<Int> 
        return new Representation(this);

    @:from static function ofRepresentation(rep:Representation<Int>)
        return new BufferViewReference(rep.get());
}

abstract NodeReference(Int) to Int {
    inline function new(v) this = v;

    public inline function get(glTF : GLTF) {
        return glTF.nodes[this];
    }

    @:to function toRepresentation():Representation<Int> 
        return new Representation(this);

    @:from static function ofRepresentation(rep:Representation<Int>)
        return new NodeReference(rep.get());
}

abstract MeshReference(Int) to Int {
    inline function new(v) this = v;

    public inline function get(glTF : GLTF) {
        return glTF.meshes[this];
    }

    @:to function toRepresentation():Representation<Int> 
        return new Representation(this);

    @:from static function ofRepresentation(rep:Representation<Int>)
        return new MeshReference(rep.get());
}

abstract SkinReference(Int) to Int {
    inline function new(v) this = v;

    public inline function get(glTF : GLTF) {
        return glTF.skins[this];
    }

    @:to function toRepresentation():Representation<Int> 
        return new Representation(this);

    @:from static function ofRepresentation(rep:Representation<Int>)
        return new SkinReference(rep.get());
}

class BufferViewParser {
    public function new(_) {}

    public function parse(v:BufferViewRaw):BufferView {
        return {
            buffer: new BufferReference(v.buffer), 
            byteLength: v.byteLength, 
            byteOffset: v.byteOffset, 
            target: switch v.target {
                case 34963: ElementArrayBuffer;
                case 34962: ArrayBuffer(v.byteStride == null ? Tight : Fixed(v.byteStride));
                default: throw 'Invalid buffer target ${v.target}';
            }
        };
    }
}

enum BufferTarget {
    ElementArrayBuffer;
    ArrayBuffer(stride : Stride);
}

enum DataType {
    @:json('SCALAR') Scalar;
    @:json('VEC2') Vec2;
    @:json('VEC3') Vec3;
    @:json('VEC4') Vec4;
    @:json('MAT2') Mat2;
    @:json('MAT3') Mat3;
    @:json('MAT4') Mat4;
}

abstract Vector3(Array<Float>) {
    inline function new(v) this = v;

    @:to function toRepresentation():Representation<Array<Float>> 
        return new Representation(this);   

    @:from static function ofRepresentation(rep:Representation<Array<Float>>) {
        var arr = rep.get();
        if (arr.length != 3)
            throw 'Invalid vector size, expected 3, got ${arr.length}';
        return new Vector3(arr);
    }
}

abstract Vector4(Array<Float>) {
    inline function new(v) this = v;

    @:to function toRepresentation():Representation<Array<Float>> 
        return new Representation(this);   

    @:from static function ofRepresentation(rep:Representation<Array<Float>>) {
        var arr = rep.get();
        if (arr.length != 4)
            throw 'Invalid vector size, expected 4, got ${arr.length}';
        return new Vector4(arr);
    }
}

abstract Matrix4(Array<Float>) {
    inline function new(v) this = v;

    @:to function toRepresentation():Representation<Array<Float>> 
        return new Representation(this);   

    @:from static function ofRepresentation(rep:Representation<Array<Float>>) {
        var arr = rep.get();
        if (arr.length != 16)
            throw 'Invalid matrix size, expected 4x4 (16), got ${arr.length}';
        return new Matrix4(arr);
    }
}

class GLTFLoader { 
    public static inline var VERSION = 2.0;
    public static var DATA_URI_PATTERN(default, never) = ~/data:.*?;base64,(.*)/;

    public static function load(path : String, verify = false) {
        var data = sys.io.File.getContent(path);
        var glTF:GLTF = Json.parse(data);

        trace(glTF.meshes[0].primitives[0].attributes.position.get(glTF).bufferView.get(glTF).buffer.get(glTF).data);
    }
}