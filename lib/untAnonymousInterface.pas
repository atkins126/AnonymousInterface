{
   Copyright:
   (c) 2020, Paulo Henrique de Freitas Passella
   (passella@gmail.com)
}

unit untAnonymousInterface;

interface

uses
   System.SysUtils, System.Rtti, System.TypInfo, System.Generics.Collections;

type
   TAnonymousInterfaceBuilder<I: IInvokable> = class
   private
      lstAnonymousMethods: TList<Pointer>;
   public
      constructor Create();
      destructor Destroy; override;
      function AddMethod(const anonymousMethod: Pointer): TAnonymousInterfaceBuilder<I>; overload;
      function AddMethod<T>(const anonymousMethod: T): TAnonymousInterfaceBuilder<I>; overload;
      function Build(): I;
   end;

   TAnonymousInterfaceBuilderFactory = class
   public
      class function CreateBuilder<I: IInvokable>(): TAnonymousInterfaceBuilder<I>;
   end;

   TAnonymousVirtualInterface<I: IInvokable> = class(TVirtualInterface)
   private
      builder: TAnonymousInterfaceBuilder<I>;
   public
      constructor Create(const builder: TAnonymousInterfaceBuilder<I>);
      destructor Destroy; override;
   end;

   TAnonymousInterface = class
   public
      class function Wrap<D: IInvokable; O>(const event: O): D; overload;
      class function Wrap<D: IInvokable>(const event: Pointer): D; overload;
   end;

implementation

{ TAnonymousInterface }

class function TAnonymousInterface.Wrap<D, O>(const event: O): D;
type
   TVtable = array [0 .. 3] of Pointer;
   PVtable = ^TVtable;
   PPVtable = ^PVtable;
begin
   if not Supports(TVirtualInterface.Create(TypeInfo(D),
      procedure(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue)
      begin
         var nArgs: TArray<TValue> := [Pointer((@event)^)] + Copy(Args, 1, Length(Args) - 1);
         var Handle: PTypeInfo := nil;

         if Assigned(Method.ReturnType) then
            Handle := Method.ReturnType.Handle;

         Result := Invoke(PPVtable((@event)^)^^[3],
            nArgs,
            Method.CallingConvention,
            Handle,
            Method.IsStatic,
            Method.IsConstructor);
      end), GetTypeData(TypeInfo(D))^.GUID, Result) then
      Result := nil;
end;

class function TAnonymousInterface.Wrap<D>(const event: Pointer): D;
type
   TVtable = array [0 .. 3] of Pointer;
   PVtable = ^TVtable;
   PPVtable = ^PVtable;
begin
   if not Supports(TVirtualInterface.Create(TypeInfo(D),
      procedure(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue)
      begin
         var nArgs: TArray<TValue> := [Pointer((@event)^)] + Copy(Args, 1, Length(Args) - 1);
         var Handle: PTypeInfo := nil;

         if Assigned(Method.ReturnType) then
            Handle := Method.ReturnType.Handle;

         Result := Invoke(PPVtable((@event)^)^^[3],
            nArgs,
            Method.CallingConvention,
            Handle,
            Method.IsStatic,
            Method.IsConstructor);
      end), GetTypeData(TypeInfo(D))^.GUID, Result) then
      Result := nil;
end;

{ TAnonymousInterfaceBuilderFactory }

class function TAnonymousInterfaceBuilderFactory.CreateBuilder<I>: TAnonymousInterfaceBuilder<I>;
begin
   Result := TAnonymousInterfaceBuilder<I>.Create();
end;

{ TAnonymousInterfaceBuilder<I> }

function TAnonymousInterfaceBuilder<I>.AddMethod(
   const anonymousMethod: Pointer): TAnonymousInterfaceBuilder<I>;
begin
   lstAnonymousMethods.Add(anonymousMethod);
   Result := Self;
end;

function TAnonymousInterfaceBuilder<I>.AddMethod<T>(
  const anonymousMethod: T): TAnonymousInterfaceBuilder<I>;
begin
   var ptrMethod: PPointer := @anonymousMethod;
   lstAnonymousMethods.Add(ptrMethod^);
   Result := Self;
end;

function TAnonymousInterfaceBuilder<I>.Build: I;
begin
   var intF := TAnonymousVirtualInterface<I>.Create(Self);
   Supports(intF, GetTypeData(TypeInfo(I))^.GUID, Result);
end;

constructor TAnonymousInterfaceBuilder<I>.Create;
begin
   inherited Create();
   lstAnonymousMethods := TList<Pointer>.Create;
end;

destructor TAnonymousInterfaceBuilder<I>.Destroy;
begin
   if Assigned(lstAnonymousMethods) then
      FreeAndNil(lstAnonymousMethods);
   inherited Destroy;
end;

{ TAnonymousVirtualInterface<I> }

constructor TAnonymousVirtualInterface<I>.Create(
   const builder: TAnonymousInterfaceBuilder<I>);
type
   TVtable = array [0 .. 3] of Pointer;
   PVtable = ^TVtable;
   PPVtable = ^PVtable;
begin
   inherited Create(TypeInfo(I));
   Self.builder := builder;

   Self.OnInvoke := procedure(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue)
      begin
         var anonymousMethod: Pointer := builder.lstAnonymousMethods[Method.VirtualIndex - 3];
         var nArgs: TArray<TValue> := [Pointer((@anonymousMethod)^)] + Copy(Args, 1, Length(Args) - 1);
         var Handle: PTypeInfo := nil;

         if Assigned(Method.ReturnType) then
            Handle := Method.ReturnType.Handle;

         Result := Invoke(PPVtable((@anonymousMethod)^)^^[3],
            nArgs,
            Method.CallingConvention,
            Handle,
            Method.IsStatic,
            Method.IsConstructor);
      end;
end;

destructor TAnonymousVirtualInterface<I>.Destroy;
begin
   if Assigned(builder) then FreeAndNil(builder);
   inherited Destroy;
end;

end.
