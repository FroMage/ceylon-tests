class Rectangle() {
    Integer width = 0;
    Integer height = 0;
    
    Integer area(){
        return width * height;
    }
}

shared class Rectangle2(width, height) {
    shared Integer width;
    shared Integer height;
    
    shared Integer area(){
        return width * height;
    }
}

shared class Rectangle3(width, height) {
    // it is here!
    if(width == 0 || height == 0){
        throw;
    }
    shared Integer width;
    shared Integer height;
    
    shared Integer area(){
        return width * height;
    }
}

class Attributes(){
    Integer n = 1;
    variable Integer i := 2;
    i++;
    Integer doubleI {
        return i * 2;
    }
    assign doubleI {
        i := doubleI / 2; 
    }
}

shared class Point(x, y){
    shared Integer x;
    shared Integer y;
}

shared class Point3D(Integer x, Integer y, z) extends Point(x,y){
    shared Integer z;
}

abstract class Shape(){
    shared formal Integer area();
    // magic: this is toString()
    //shared actual default String string {
    //    return "Abstract area: " area.string " m2";
    //}
}

class Square(Integer width) extends Shape(){
    shared actual Integer area() { 
        return width * width;
    }
    //shared actual String string = "Square area: " area.string " m2";
}

class Rectangle4(Integer width = 2, Integer height = 3){
    shared Integer area(){
        return width * height;
    }
}
void makeRectangle(){
    Rectangle4 rectangle = Rectangle4();
    Rectangle4 rectangle2 = Rectangle4 {
        width = 3;
        height = 4;
    };
}

interface ShapeSwitch {}
class CircleSwitch () satisfies ShapeSwitch {}
class RectangleSwitch () satisfies ShapeSwitch {}

void workWithRectangle(RectangleSwitch rect){}
void workWithCircle(CircleSwitch circle){}
void workWithShape(ShapeSwitch shape){}

void supportsSubTyping(ShapeSwitch fig){
    switch(fig)
    case(is RectangleSwitch){
        workWithRectangle(fig);
    }
    case(is CircleSwitch){
        workWithCircle(fig);
    }
    else{
        workWithShape(fig);
    }
}

interface Figure3D {
    shared formal Float area;
    shared formal Float depth;
    shared formal Float volume;
}

class Cube(Float width) satisfies Figure3D {
    shared actual Float area = width * width;
    shared actual Float depth = width;
    shared actual Float volume = area * depth;
}

class Cylinder(Integer radius, depth) satisfies Figure3D {
    shared actual Float area = 3.14 * radius ** 2;
    shared actual Float depth;
    shared actual Float volume = area * depth;
}
/*
interface Figure3D2 {
    shared formal Float area;
    shared formal Float depth;
    shared Float volume {
        return area * depth;
    }
}

class Cube2(Float width) satisfies Figure3D2 {
    shared actual Float area = width * width;
    shared actual Float depth = width;
}

class Cylinder2(Integer radius, Float depth) satisfies Figure3D2 {
    shared actual Float area = 3.14 * radius ** 2;
    shared actual Float depth = depth;
}

Integer attribute = 1;
Integer attribute2 { return 2; }
void method(){}
interface Interface{}

class Class(Integer x){
    Integer attribute = x;
    Integer attribute2 { return x; }
    class InnerClass(){}
    interface InnerInterface{}
    
    void method(Integer y){
        Integer attribute;
        Integer attribute2 { return y; }
        class LocalClass(){}
        interface LocalInterface{}
        void innerMethod(){}
    }
}

class Border(Integer padding, Integer weight){}

class Column(String heading, Integer width, String content(Integer row)){}

class Table(String title, Integer rows, Border border, Column... columns){}

Table table = Table {
    title = "Squares";
    rows = 5;
    border = Border {
        padding = 2;
        weight = 1;
    };
    Column {
        heading = "x";
        width = 10;
        String content(Integer row) {
            return row.string;
        }
    },
    Column {
        heading = "x**2";
        width = 12;
        String content(Integer row) {
            return (row**2).string;
        }
    }
};
*/
void types(){
    Integer i = -20;
    Integer n = 10.times(2); // no primitive types
    Float f = 3.14;
    String[] s = {"foo", "bar"}; // inference
    Number[] r = 1..2;       // intervals
    Boolean b = true;        // enumerated types
    Cube cube = Cube(2.0);   // constructor
    // inference
    function makeCube(Float width){ 
        return Cube(width);
    }
    value cube2 = makeCube(3.0);
}

Cube[] cubeList(){ return {}; }

void typeSafety(){
    // optional?
    Cube? cubeOrNoCube() { return null; }
    Cube? cube = cubeOrNoCube();
    
//    print(cube.area.string); // compile error
    
    if(exists cube){
        print(cube.area.string);
    }else{
        print("Got no cube");
    }

    // default value
    Cube cube2 = cubeOrNoCube() ? Cube(3.0);
    // nullsafe access
    Float? area = cube?.area;
    // nullsafe array access
    Cube[]? maybeList = cubeList();
    Cube? c = maybeList?[2];
}

void dealingWithLists(){
    Cube[] list = cubeList();
    if(nonempty list){
        print(list.first.string);
    }
    // sequence
    for(Cube cube in list){
        print(cube.string);
    }else{
        print("No cubes!");
    }
    // range
    for(Integer n in +0..+10){
        print(n.string);
    }
    

    Integer[] numbers = {1,2,3};
    // slices
    Integer[] subList = numbers[1..2];
    Integer[] rest = numbers[1...];
    // map/spread
    Integer[] successors = numbers[].successor;
}

class Apple() {
    shared void eat(){}
}

class Garbage() {
    shared void throwAway(){}
}

void unions(){
    Sequence<Apple|Garbage> boxes = {Apple(), Garbage()};
    for(Apple|Garbage box in boxes){
        print(box.string);
        if(is Apple box){
            box.eat();
        }else if(is Garbage box){
            box.throwAway();
        }
    }
}

interface Food {
    shared formal void eat(); 
}

interface Drink {
    shared formal void drink(); 
}

class Guinness() satisfies Food & Drink {
    shared actual void drink() {}
    shared actual void eat() {}
}

void intersections(){
    Food & Drink specialStuff = Guinness();
    specialStuff.drink();
    specialStuff.eat();
}
