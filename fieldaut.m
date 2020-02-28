//freeze;

declare type FldAut;
declare attributes FldAut :
  L, // the field
  map, // the mapping
  elt, // the element in the automorphism group
  isom; // the isomorphism between the group and the set of maps

/* constructors */

intrinsic FieldAutomorphism(L::Fld, g::GrpPermElt) -> FldAut
{.}
  alpha := New(FldAut);
  alpha`L := L;
  gal, aut, psi := AutomorphismGroup(L);
  require g in gal :
  "Group element must be in the automorphism group of the field!";
  alpha`elt := g;
  alpha`map := psi(g);
  alpha`isom := psi;

  return alpha; 
end intrinsic;

/* Printing */
intrinsic Print(alpha::FldAut)
{.}
  printf "Field Automorphism of %o", alpha`L;
end intrinsic;

/* access */

intrinsic BaseField(alpha::FldAut) -> Fld
{.}
  return alpha`L;
end intrinsic;

intrinsic Order(alpha::FldAut) -> RngIntElt
{.}
  return Order(alpha`elt);
end intrinsic;

intrinsic FixedField(alpha::FldAut) -> Fld
{.}
  return FixedField(alpha`L, [alpha`map]);
end intrinsic;

/* arithmetic */

intrinsic '^'(alpha::FldAut, n::RngIntElt) -> FldAut
{.}
  beta := New(FldAut);
  beta`L := alpha`L;
  beta`elt := alpha`elt^n;
  beta`isom := alpha`isom;
  beta`map := beta`isom(beta`elt);

  return beta;
end intrinsic;

intrinsic Inverse(alpha::FldAut) -> FldAut
{.}
  return alpha^(-1);
end intrinsic;

intrinsic '*'(alpha::FldAut, beta::FldAut) -> FldAut
{.}
  require BaseField(alpha) eq BaseField(beta) :
     "Automorphisms should be of the same field";
  
  gamma := New(FldAut);
  gamma`L := alpha`L;
  gamma`elt := alpha`elt * beta`elt;
  gamma`isom := alpha`isom;
  gamma`map := beta`map * alpha`map;

  return gamma;
end intrinsic;

intrinsic 'eq'(alpha::FldAut, beta::FldAut) -> BoolElt
{.}
  return BaseField(alpha) eq BaseField(beta) and alpha`elt eq beta`elt;
end intrinsic;

intrinsic IsIdentity(alpha::FldAut) -> BoolElt
{.}
   return alpha`elt eq Parent(alpha`elt)!1;
end intrinsic;

/* Evaluation */

intrinsic '@'(x::FldElt, alpha::FldAut) -> FldElt
{.}
  return alpha`map(x);
end intrinsic;

intrinsic '@'(v::ModTupFldElt[Fld], alpha::FldAut) -> ModTupFldElt
{.}
  V := Parent(v);
  require BaseField(V) eq BaseField(alpha) : "map must be defined on elements!";
  return V![alpha(v[i]) : i in [1..Dimension(V)]];
end intrinsic;

intrinsic '@'(a::AlgMatElt[Fld], alpha::FldAut) -> AlgMatElt[Fld]
{.}
  A := Parent(a);
  require BaseRing(A) eq BaseField(alpha) : "map must be defined on elements!";
  return A![[alpha(a[i,j]) : j in [1..Degree(A)]]
				  : i in [1..Degree(A)]];
end intrinsic;

intrinsic '@'(I::RngOrdFracIdl[FldOrd], alpha::FldAut) -> RngOrdFracIdl[FldOrd]
{.}
  L := BaseField(alpha);
  Z_L := RingOfIntegers(L);
  require Z_L eq Order(I) :
    "Fractional ideal must be in the ring of integers of the field hte automorphism is acting on.";
  return ideal<Z_L | [alpha`map(g) : g in Generators(I)]>;
end intrinsic;
