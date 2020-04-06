//freeze;
/****-*-magma-**************************************************************
                                                                            
                    Algebraic Modular Forms in Magma                          
                            Eran Assaf                                 
                                                                            
   FILE: representation.m (class for group representations)

   04/03/20: Added references to original representation in cases of
             dual and symmetric representations. Also added a flag for
             the standard representation, so that upon construction we can
             match the base rings of group and module, even when loading
             from a file.
             Changed the action description to include the representation
             as an argument, and so be self-contained.
             Modified the names in tensor product to be strings, and so 
             simplify saving and loading from files.
             Added the function build_rep_params that constructs all the 
             parameters of the representation.
             Added the ChangeRing Intrinsic.
             Modified construction of homomorphisms to support loading from
             files.

   04/01/20: Added the attribute action_desc to a representation, so we will
             be able to read and write to disk (serialization).
             This was needed because UserProgram does not support any, so 
             to record the action, we actually record the code that
             produces it.
             Added params to constructor, also to be able to load from disk
             when there are special flags to the representation.
             Changed all constructors to comply.
             Added Magma level printing.
             Changed 'eq' accordingly.

   03/29/20: Added verbose to FixedSubspace. 
             Added the function getActionMatrix to get the matrix 
             representing an element in a GrpLie in a certain weight 
	     representation.
             Added a FixedSubspace intrinsic for such a case.
             Added a constructor for a GroupRepresentation from
             a Lie group and a weight - good for finite characteristic.

   03/26/20: Modified FixedSubspace to handle representation over any
             coefficient ring.

   03/25/20: Fixed the (horrible!) bug in getActionHom by transposing the 
             matrices(!!!)

   03/23/20: Changed getGL3HighestWeightRep to work also when either
             a or b are zero.

   03/16/20: Added basic documentation
   	     Added operator @@ (preimage) 

   03/13/20: Added handling of homomorphisms
   	     Separated CombinatorialFreeModule to a separate file.

   03/12/20: started writing this file
 
 ***************************************************************************/

forward projLocalization;

// This should have been done using GModule
// But for some reason, it's really terrible, so we are doing our own
// This is currently built on top of combinatorial free modules
// to allow for nice (= meaningful) representations of the elements

declare type GrpRep[GrpRepElt];
declare attributes GrpRep :
		   // the group
		   G,
	// the module
	M,
	// the action on basis elements
	action,
	action_desc,
	// an associative array recording the action matrix of some elements
	// everytime we apply an element, it is updated.
	// In the future, might want to add an option to compute the operation on
	// a single element without computing the matrix.
	act_mats,
	// List of finite subgroups that can be generated by elements of finite
	// order for which we have computed the action.
	// In theory, would like just to save the group generated by all elements
	// for which we have computed the action matrix, but we (=magma) don't know
	// how to solve the word problem for matrix groups of infinite order.
	known_grps,
	// This is assigned only if our representation is a tensor product, since
	// in this case we can compute the action matrix easily by computing the
	// dual representation
	dual,
	// standard representation
	standard,
	// symmetric representation
	symmetric, 
	// tensor product of the matrices.
	tensor_product,
	// This is assigned only if our representation is a pullback
	// in this case we can compute the action matrix by computing it
	// for the space we are pulling back from
	pullback,
	mat_to_elt,
	weight,
	// In case this is a subrepresentation, its ambient representation
	ambient,
	// In case this is a subrepresentation, the embedding into its ambient.
	embedding;

declare attributes GrpRepElt :
		   // the actual element in the module
		   m,
	// its parent
	parent;

/* constructors */

// action_desc is a string description of the action,
// needed for serializaition, since Map does not really support it
intrinsic GroupRepresentation(G::Grp, M::CombFreeMod,
			action_desc::MonStgElt : params := [* *] ) -> GrpRep
{Constructs a group representation for the group G on the combinatorial free module
M, such that the action on basis elements G x Basis(M) -> M is described by the map action .}

  V := New(GrpRep);
  V`G := G;
  V`M := M;

  param_array := AssociativeArray();

  // Store meta data.
  for entry in params do param_array[entry[1]] := entry[2]; end for;

  if IsDefined(param_array, "TENSOR_PRODUCT") then
      V`tensor_product := param_array["TENSOR_PRODUCT"];
  end if;

  if IsDefined(param_array, "PULLBACK") then
      V`pullback := param_array["PULLBACK"];
  end if;

  if IsDefined(param_array, "AMBIENT") then
      W := param_array["AMBIENT"];
      iota := param_array["EMBEDDING"];
      fromFile := IsDefined(param_array, "FROM_FILE"); 
      V`embedding := Homomorphism(V, W, iota : FromFile := fromFile);
      V`ambient := Codomain(V`embedding);
  end if;

  if IsDefined(param_array, "DUAL") then
      V`dual := param_array["DUAL"];
  end if;

  if IsDefined(param_array, "STANDARD") then
      V`standard := param_array["STANDARD"];
      // In this case it is crucial that the module and the group
      // will have the same base ring
      V`M := CombinatorialFreeModule(BaseRing(G), M`names);
  end if;

  if IsDefined(param_array, "SYMMETRIC") then
      V`symmetric := param_array["SYMMETRIC"];
  end if;

  //  V`action := action;
  V`action_desc := action_desc;
  action := eval action_desc;
  V`action := map< CartesianProduct(V`G, [1..Dimension(V`M)]) -> V`M |
		 x :-> action(x[1], x[2], V)>;
/*
  require (Domain(V`action) eq CartesianProduct(G, [1..Dimension(M)])) and
	  (Codomain(V`action) eq M) :
	"action should have domain G x [1..Dimension(M)], and codomain M.";
*/
  
  V`act_mats := AssociativeArray();
  V`known_grps := [sub<V`G|1>];
  V`act_mats[G!1] := IdentityMatrix(BaseRing(V`M), Dimension(V`M));
  return V;
end intrinsic;

// At the moment, we assume that the generators are
// for the subrepresentation as a module
// (i.e. without computing the G-action)
// Also, (bug / feature?) we do not check that this is indeed a subrepresentation

// Remark - this should have been implemented using SubConstructor
// However, SubConstructor would always return a Map,
// and something goes completely wrong with maps between these objects.

intrinsic Subrepresentation(V::GrpRep, t::.) -> GrpRep, GrpRepHom
{Computes the subrepresentation of V whose underlying free module
 is generated by t.}
  if Type(t) eq SeqEnum then t := Flat(t); else t := [t]; end if;
  t := [V!x : x in t];
  N, i := SubCFModule(V`M, [v`m : v in t]);
  //  N_idx := [1..Dimension(N)];
  action_desc := Sprintf("           
  	      function action(g, m, V)
	      	       i := V`embedding;
      	      	       return (g * (V`ambient)!(i((V`M).m))`m)@@i;
  	      end function;
  	      return action;
	      ");
/*  action := map< CartesianProduct(V`G, N_idx) -> N |
	       x :-> ((x[1] * V!(i(N.(x[2]))))`m)@@i>;*/
//  U`ambient := V;
//  U`embedding := iota;
  U_params := [* <"AMBIENT", V>, <"EMBEDDING", i> *];
  U := GroupRepresentation(V`G, N, action_desc :
			   params := U_params);
  // iota := Homomorphism(U, V, i);
  return U, /* iota*/ U`embedding;
end intrinsic;

/* constructors of some special cases of representations */

intrinsic TrivialRepresentation(G::Grp, R::Rng : name := "v") -> GrpRep
{Constructs the trivial representation for G over the ring R.}
  M := CombinatorialFreeModule(R, [name]);
//  a := map < CartesianProduct(G,[1..Dimension(M)]) -> M | x :-> M.(x[2])>;
  a := Sprintf("
  function action(g,m,V)
  	   return (V`M).m;
  end function; 
  return action;
  ");
  return GroupRepresentation(G, M, a);
end intrinsic;

intrinsic StandardRepresentation(G::GrpMat : name := "x") -> GrpRep
{Constructs the standard representation of the matrix group G its ring of definition R, i.e. the representation obtained by considering its given embedding in GL_n acting on R^n by invertible linear transformations.}
  n := Degree(G);
  names := [name cat IntegerToString(i) : i in [1..n]];
  M := CombinatorialFreeModule(BaseRing(G), names);
/*  a := map< CartesianProduct(G, [1..Dimension(M)]) -> M |
	  x :-> M!((M.(x[2]))`vec * Transpose(x[1]))>;*/
  a := Sprintf("
  function action(g,m,V)
	return (V`M)!(((V`M).m)`vec * Transpose(g));
  end function;
  return action;
  ");
  return GroupRepresentation(G, M, a : params := [* <"STANDARD", true> *]);
end intrinsic;

intrinsic SymmetricRepresentation(V::GrpRep, n::RngIntElt) -> GrpRep
{Constructs the representation Sym(V).}
    R := BaseRing(V);	  
    R_X := PolynomialRing(R, Rank(V));
    AssignNames(~R_X, V`M`names);
    S := MonomialsOfDegree(R_X, n);
    M := CombinatorialFreeModule(R, S);
//  gens := RModule(R_X, Rank(V))!SetToSequence(MonomialsOfDegree(R_X,1));
  /*
  function action(g,m)
      coeffs := [RModule(R_X, Rank(V)) | Eltseq(g * V.i) : i in [1..Dimension(V)]];
      ys := Vector(gens) * Transpose(Matrix(coeffs));
      ans := Evaluate(S[m], Eltseq(ys));
      ans_coeffs, mons := CoefficientsAndMonomials(ans);
      idxs := [Index(mons, name) : name in M`names];
      return &+[ans_coeffs[idxs[i]] * M.i : i in [1..#idxs] | idxs[i] ne 0];
  end function;
  a := map< CartesianProduct(V`G, [1..Dimension(M)]) -> M |
	  x :-> action(x[1], x[2]) >;
 */
  a := Sprintf("
  function action(g,m,V)
      R := Universe(V`M`names);
      gens := RModule(R, Ngens(R))![R.i : i in [1..Ngens(R)]];
      coeffs := [RModule(R, Rank(V`symmetric)) | Eltseq((V`symmetric`G!g) * (V`symmetric).i) : i in [1..Dimension(V`symmetric)]];
      ys := Vector(gens) * Transpose(Matrix(coeffs));
      ans := Evaluate(V`M`names[m], Eltseq(ys));
      ans_coeffs, mons := CoefficientsAndMonomials(ans);
      idxs := [Index(mons, name) : name in V`M`names];
      return &+[ans_coeffs[idxs[i]] * (V`M).i : i in [1..#idxs] | idxs[i] ne 0];
  end function;
  return action;
  ");
  return GroupRepresentation(V`G, M, a : params := [* <"SYMMETRIC", V> *]);
end intrinsic;

intrinsic DualRepresentation(V::GrpRep) -> GrpRep
{Constructs the dual representation of V.}
  R := BaseRing(V);
  names := [Sprintf("%o^*",b) : b in Basis(V)]; 
  M := CombinatorialFreeModule(R, names);
  /*
  function action(g,m)
      v := V!Eltseq(M.m);
      return M!(Eltseq(Transpose(g)^(-1) * v));
  end function;
  a := map< CartesianProduct(V`G, [1..Dimension(M)]) -> M | x :-> action(x[1], x[2]) >;*/
  a := Sprintf("
  function action(g,m,V)
      v := (V`dual)!Eltseq((V`M).m);
      return (V`M)!(Eltseq(Transpose((V`dual`G)!g)^(-1) * v));
  end function;
  return action;
  ");
  return GroupRepresentation(V`G, M, a : params := [* <"DUAL", V> *]);
end intrinsic;

intrinsic TensorProduct(V::GrpRep, W::GrpRep) -> GrpRep
{Constructs the tensor product of the representations V and W, with diagonal action.}
  R := BaseRing(V);
  names := [Sprintf("<%o, %o>", v, w) : v in V`M`names, w in W`M`names];
  M := CombinatorialFreeModule(R, names);
/*  function action(g,m)
      vecs := [Vector(Eltseq(g*n)) : n in M`names[m]];
      return M!(TensorProduct(vecs[1], vecs[2]));
  end function;
  a := map< CartesianProduct(V`G, [1..Dimension(M)]) -> M |
	  x :-> action(x[1], x[2]) >; */
  a := Sprintf("
  function action(g,m,V)
      ops := [(V`tensor_product[i]).(V`M`names[m][i]) : i in [1..2]];
      gs := [(V`tensor_product[i]`G)!g : i in [1..2]];
      vecs := [Vector(Eltseq(gs[i]*ops[i])) : i in [1..2]];
      return (V`M)!(TensorProduct(vecs[1], vecs[2]));
  end function;
  return action;  
  ");
  ret := GroupRepresentation(V`G, M, a :
			     params := [* <"TENSOR_PRODUCT", [V,W]> *]);
//  ret`tensor_product := [V,W];
  return ret;
end intrinsic;

intrinsic Pullback(V::GrpRep, /* f::Map[Grp, Grp] */
		      f_desc::MonStgElt, H::Grp) -> GrpRep
{Constructs the pullback of the representation V along the
group homomorphism f. Does not verify that f is a group homomorphism}
  M := V`M;
  f := (eval f_desc)(H);
  G := Domain(f);
/*  action := map< CartesianProduct(G, [1..Dimension(M)]) -> M |
	       x :-> V`action(f(x[1]), x[2]) >;*/
  action := Sprintf("
  f := eval %m;
  V_action := eval %m;
  function action(g,m,V)
    return V_action(f(g), m);
  end function;
  return action;
  ", f_desc, V`action_desc);
  ret := GroupRepresentation(G, M, action :
			     params := [* <"PULLBACK", <V, f> > *]);
//  ret`pullback := < V, f >;
  return ret;
end intrinsic;

// since magma doesn't support localization in arbitrary number fields
// we make a small patch for that
function projLocalization(g, proj)
    denom := Parent(g)!ScalarMatrix(Degree(g),Denominator(g));
    numerator := denom*g;
    f := hom< MatrixAlgebra(Domain(proj),Degree(g)) ->
			  MatrixAlgebra(Codomain(proj),Degree(g)) | proj >;
    f_gl := hom< GL(Degree(g), Domain(proj)) ->
		   GL(Degree(g), Codomain(proj)) | x :-> f(Matrix(x)) >;
    return f_gl(numerator) * f_gl(denom)^(-1);
end function;
// Then one can pullback via something like
// f := map< GL(3,K) -> GL(3,F7) | x :-> projLocalization(x, mod_root_7)>;
// even though f is not defined on all GL(3,K), but only on a localization

/* access and properties */

intrinsic Rank(V::GrpRep) -> RngIntElt
{The rank of the free module underlying the representation V.}
  return #Basis(V);	  
end intrinsic;

intrinsic Dimension(V::GrpRep) -> RngIntElt
{The rank of the free module underlying the representation V.}
  return Rank(V);
end intrinsic;

intrinsic Ngens(V::GrpRep) -> RngIntElt
{The rank of the free module underlying the representation V.}
  return Rank(V);
end intrinsic;

intrinsic Basis(V::GrpRep) -> SeqEnum[GrpRepElt]
{Returns a basis for the free module underlying the representation V.}
  return [V!v : v in Basis(V`M)];
end intrinsic;

intrinsic BaseRing(V::GrpRep) -> Rng
{Returns the ring over which V is defined.}
  return BaseRing(V`M);
end intrinsic;

function build_rep_params(V)
    params := [* *];
    if assigned V`tensor_product then
	Append(~params, < "TENSOR_PRODUCT", V`tensor_product >);
    end if;
    if assigned V`dual then
	Append(~params, < "DUAL", V`dual >);
    end if;
    if assigned V`standard then
	Append(~params, < "STANDARD", V`standard >);
    end if;
    if assigned V`symmetric then
	Append(~params, < "SYMMETRIC", V`symmetric >);
    end if;
    if assigned V`pullback then
	Append(~params, < "PULLBACK", V`pullback >);
    end if;
    if assigned V`ambient then
	images := [V`embedding(V.i)`m : i in [1..Dimension(V)]];
	iota := Homomorphism(V`M, V`ambient`M, images);
	Append(~params, < "AMBIENT", V`ambient >);
	Append(~params, < "EMBEDDING", iota >);
    end if;
    return params;
end function;

intrinsic ChangeRing(V::GrpRep, R::Rng) -> GrpRep
{return the Group Representation with base ring changed to R.}
  return GroupRepresentation(V`G, ChangeRing(V`M,R), V`action_desc
			   : params := build_rep_params(V));
end intrinsic;

/* printing */

intrinsic Print(V::GrpRep, level::MonStgElt)
{.}
  if level eq "Magma" then
      params := build_rep_params(V);
      Append(~params, < "FROM_FILE", true>);
      printf "GroupRepresentation(%m, %m, %m : params := %m)",
	     V`G, V`M, V`action_desc, params;
      return;
  end if;
  printf "%o with an action of %o", V`M, V`G; 
end intrinsic;		   

/* generators and coercion */ 

intrinsic '.'(V::GrpRep, i::RngIntElt) -> GrpRepElt
{.}
  return GroupRepresentationElement(V, V`M.i);	     
end intrinsic;

intrinsic IsCoercible(V::GrpRep, x::Any) -> BoolElt, .
{.}
  if Type(x) eq GrpRepElt and Parent(x) eq V then return true, x; end if;
  is_coercible, v := IsCoercible(V`M, x);
  if is_coercible then
      return true, GroupRepresentationElement(V, v);
  else
      return false, "Illegal Coercion";
  end if;
end intrinsic;

intrinsic 'in'(elt::GrpRepElt, V::GrpRep) -> BoolElt
{.}
  return Parent(elt) eq V;
end intrinsic;

/***************************************************

GrpRepElt - an element of a group representation

****************************************************/

/* constructor */
intrinsic GroupRepresentationElement(V::GrpRep, m::CombFreeModElt) -> GrpRepElt
{Construct an element of the group representation whose underlying vector is m.}
  elt := New(GrpRepElt);
  elt`m := m;
  elt`parent := V;
  
  return elt;
end intrinsic;

/* access */

intrinsic Parent(elt::GrpRepElt) -> GrpRep
{.}
  return elt`parent;	  
end intrinsic;

intrinsic Eltseq(elt::GrpRepElt) -> SeqEnum
{.}
  return Eltseq(elt`m);
end intrinsic;

/* printing */

intrinsic Print(elt::GrpRepElt, level::MonStgElt)
{.}
  if level eq "Magma" then
      printf "%m ! %m", Parent(elt), Eltseq(elt);
      return;
  end if;
  printf "%o", elt`m;
end intrinsic;

/*
 Computing the group action 
*/

// verifyKnownGroups is a procedure for cases of incoherent execution,
// e.g. execution was interrupted. It makes sure that the known groups
// are updated correctly.

procedure verifyKnownGroups(V)
    idxs := [[i : i in [1..Ngens(grp)] | grp.i in Keys(V`act_mats)] :
	     grp in V`known_grps];
    V`known_grps := [sub<V`G | [V`known_grps[j].i : i in idxs[j]]> : j in [1..#idxs]];
end procedure;

// getActionHom returns the homomorphism from the finite group grp to the
// automorphisms of the representation. 
function getActionHom(V, grp)
    GL_V := GL(Dimension(V), BaseRing(V));
    verifyKnownGroups(V); // this is in case there was some interrupt
    return hom< grp -> GL_V |
		  [Transpose(V`act_mats[grp.i]) : i in [1..Ngens(grp)]]>;
end function;

// At the moment, every time we compute the complete image of g in GL_V
// and store it for future use.
// When dimensions will be high, we would probably no longer wish to do that.

intrinsic getMatrixAction(V::GrpRep, g::GrpElt) -> GrpMatElt
{Computes the martix describing the action of g on V.}
  // In the cases of pullbacks and weight representations
  // we don't record anything, just compute from the underlying structure
  if assigned V`pullback then
      W := V`pullback[1];
      f := V`pullback[2];
      return getMatrixAction(W, f(g));
  end if;
  if assigned V`mat_to_elt then
      if GetVerbose("AlgebraicModularForms") ge 3 then
	  printf "Getting matrix action for element\n%o\n ", g;
	  printf " in representation over %o.\n", BaseRing(V`G);
	  printf "calculating element in algebraic group...";
      end if;
      elt := V`mat_to_elt(g);
      if GetVerbose("AlgebraicModularForms") ge 3 then
	  printf "calculating matrix in weight for %o.\n", elt;
      end if;
      mat := Transpose(V`weight(elt));
      if GetVerbose("AlgebraicModularForms") ge 3 then
	  printf "Done!\n";
      end if;
      // This is in the case we projected into PGL
      return ChangeRing(mat, BaseRing(V`G));
  end if;
  verifyKnownGroups(V); // this is in case there was some interrupt

  if HasFiniteOrder(g) then
      is_known := exists(grp){grp : grp in V`known_grps | g in grp};
  else
      is_known := g in Keys(V`act_mats);
  end if;

  if not is_known then
      if HasFiniteOrder(g) then
	  grp_idx := 0;
	  for j in [1..#V`known_grps] do 
	      new_grp := sub<V`G | V`known_grps[j], g>;
	      if IsFinite(new_grp) then
		  V`known_grps[j] := new_grp;
		  grp_idx := j;
		  break;
	      end if;
	  end for;
	  if grp_idx eq 0 then
	      Append(~V`known_grps, sub<V`G | g>);
	      grp_idx := #V`known_grps;
	  end if;
	  grp := V`known_grps[grp_idx];
      end if;
      if assigned V`tensor_product then
	  V1, V2 := Explode(V`tensor_product);
	  V`act_mats[g] := TensorProduct(
		ChangeRing(getMatrixAction(V1, (V1`G)!g), BaseRing(V)),
		ChangeRing(getMatrixAction(V2, (V2`G)!g), BaseRing(V)));
      else if assigned V`ambient then
	       phi := Matrix(V`embedding`morphism);
	       phi_T := Transpose(phi);
	       mat_g := getMatrixAction(V`ambient, (V`ambient`G)!g);
	       V`act_mats[g] := phi * mat_g * phi_T * (phi * phi_T)^(-1); 
	   else
	       V`act_mats[g] := Matrix([V`action(g, i)`vec : i in [1..Dimension(V)]]);
	   end if;
      end if;
  end if;

  if HasFiniteOrder(g) then
      act_hom := getActionHom(V, grp);
      return Transpose(act_hom(g));
  else
      return V`act_mats[g];
  end if;
  
end intrinsic;

/* arithmetic operations */

intrinsic '*'(g::GrpElt, v::GrpRepElt) -> GrpRepElt
{.}

  V := Parent(v);
  require g in V`G : "element must be in the group acting on the space";
  
  g_act := getMatrixAction(V,g);
  
  return V!(v`m`vec * g_act);
end intrinsic;

intrinsic '+'(elt_l::GrpRepElt, elt_r::GrpRepElt) -> GrpRepElt
{.}
  require Parent(elt_l) eq Parent(elt_r) : "elements must belong to the same 
  	  		   		   	     representation";
  V := Parent(elt_l);
  return GroupRepresentationElement(V, elt_l`m + elt_r`m);
end intrinsic;

intrinsic '-'(elt_l::GrpRepElt, elt_r::GrpRepElt) -> GrpRepElt
{.}
  require Parent(elt_l) eq Parent(elt_r) : "elements must belong to the same 
  	  		   		   	     representation";
  V := Parent(elt_l);
  return GroupRepresentationElement(V, elt_l`m - elt_r`m);
end intrinsic;

intrinsic '*'(scalar::RngElt, elt::GrpRepElt) -> GrpRepElt
{.}	     
  V := Parent(elt);
  require scalar in BaseRing(V) : "scalar is not in the base ring";
  return GroupRepresentationElement(V, scalar * elt`m);
end intrinsic;

/* booleans, equality and hashing */

intrinsic 'eq'(V1::GrpRep, V2::GrpRep) -> BoolElt
{.}
  // In theory, we could have equivalent action descriptions
  // but we cannot really check this
  return V1`M eq V2`M and V1`G eq V2`G and
         Split(V1`action_desc, " \t\n") eq Split(V2`action_desc, " \t\n");
end intrinsic;

intrinsic Hash(V::GrpRep) -> RngIntElt
{.}
  // far from optimal, since magma doesn't know how to hash functions or groups
  // Should fix it in time (create a class wrapping functions having hash
  return Hash(<V`M, V`action>);
end intrinsic;

intrinsic 'eq'(v1::GrpRepElt, v2::GrpRepElt) -> BoolElt
{.}
  V := Parent(v1);
  if V ne Parent(v2) then return false; end if;
  return Eltseq(v1) eq Eltseq(v2);
end intrinsic;

intrinsic Hash(v::GrpRepElt) -> RngIntElt
{.}
  return Hash(<v`m, v`parent>);
end intrinsic;

intrinsic 'in'(v::., V::GrpRep) -> BoolElt
{Returns whether v is in V}
  return Parent(v) eq V;
end intrinsic;

// This function is here simply due to our interest in GL3, U3, O3
// TODO : 1. Move it to the tests and examples.
//        2. Create a more general function for such constructions for
//           arbitrary dimensions.

function getGL3Rep(a, b, K)
    G := GL(3, K);
    V := StandardRepresentation(G);
    V_dual := DualRepresentation(V);
    sym_a := SymmetricRepresentation(V,a);
    sym_b_dual := SymmetricRepresentation(V_dual,b);
    return TensorProduct(sym_a, sym_b_dual);
end function;

/***************************************************

GrpRepHom - Homomorphism of group representations

****************************************************/
// for some reason, just havin map<V->W|f> doesn't work. no idea why

declare type GrpRepHom;
declare attributes GrpRepHom :
		   domain,
	codomain,
	morphism;

/* constructors */

intrinsic Homomorphism(V::GrpRep, W::GrpRep, f::UserProgram) -> GrpRepHom
{Construct a homomorphism of group representation described by f. Note: the constructor does not verify that the map indeed describes a homomorphism of group representations.}
  require BaseRing(V) eq BaseRing(W) : "Represenations should have the same coefficient ring";
  phi := New(GrpRepHom);
  phi`domain := V;
  phi`codomain := W;
  phi`morphism := hom<V`M`M -> W`M`M | [f(V.i)`m`vec : i in [1..Dimension(V)]]>;

  return phi;
end intrinsic;

intrinsic Homomorphism(V::GrpRep, W::GrpRep, f::Map) -> GrpRepHom
{Construct a homomorphism of group representations described by f. Note: the constructor does not verify that the map indeed describes a homomorphism of group representations.}
  require BaseRing(V) eq BaseRing(W) : "Represenations should have the same coefficient ring";
  phi := New(GrpRepHom);
  phi`domain := V;
  phi`codomain := W;

  require (Domain(f) eq V`M) and (Codomain(f) eq W`M) :
	"Map should be defined on the combinatorial modules of the representations"; 
  phi`morphism := hom<V`M`M -> W`M`M | [f((V.i)`m)`vec : i in [1..Dimension(V)]]>;

  return phi;
end intrinsic;

intrinsic Homomorphism(V::GrpRep, W::GrpRep,
				     basis_images::SeqEnum :
		       FromFile := false) -> GrpRepHom
{Construct a homomorphism of group representations such that the images of the basis elements of V map to basis_images. Note: the constructor does not verify that the map indeed describes a homomorphism of group representations.}
  phi := New(GrpRepHom);
  phi`domain := V;
  if FromFile then
      W := ChangeRing(W, BaseRing(V));
  else
      require BaseRing(V) eq BaseRing(W) : "Represenations should have the same coefficient ring";
  end if;
  phi`codomain := W;

  require IsEmpty(basis_images) or IsCoercible(W,basis_images[1]) :
	"images should be in the codomain representation"; 
  phi`morphism := hom<V`M`M -> W`M`M | [Eltseq(W!v) : v in basis_images]>;

  return phi;
end intrinsic;

intrinsic Homomorphism(V::GrpRep, W::GrpRep,
				     f::CombFreeModHom
		      : FromFile := false) -> GrpRepHom
{Construct a homomorphism of group representations described by f. Note: the constructor does not verify that the map indeed describes a homomorphism of group representations.}
  phi := New(GrpRepHom);
  phi`domain := V;
  if FromFile then
      W := ChangeRing(W, BaseRing(V));
      images := [f(Domain(f).i)`vec : i in [1..Dimension(V)]];
      f := Homomorphism(V`M, W`M,
		[Vector(ChangeRing(x,BaseRing(W`M))) : x in images]);
  else
      require BaseRing(V) eq BaseRing(W) : "Represenations should have the same coefficient ring";
      require (Domain(f) eq V`M) and (Codomain(f) eq W`M) :
	"Map should be defined on the combinatorial modules of the representations"; 
  end if;
  phi`codomain := W;
  
  phi`morphism := hom<V`M`M -> W`M`M | [Eltseq(f((V.i)`m)) : i in [1..Dimension(V)]]>;
 
  return phi;
end intrinsic;

/* access */

intrinsic Domain(phi::GrpRepHom) -> GrpRep
{.}
  return phi`domain;
end intrinsic;

intrinsic Codomain(phi::GrpRepHom) -> GrpRep
{.}
  return phi`codomain;
end intrinsic;

/* printing */

intrinsic Print(phi::GrpRepHom, level::MonStgElt)
{.}
  if level eq "Magma" then
      images := [Eltseq(phi(Domain(phi).i)) :
		 i in [1..Dimension(Domain(phi))]];
      printf "Homomorphism(%m, %m, %m : FromFile := true)",
	     Domain(phi), Codomain(phi), images;
      return;
  end if;
  printf "Homorphism from %o to %o", Domain(phi), Codomain(phi);
end intrinsic;

/* Evaluation, image and pre-image */

intrinsic Evaluate(phi::GrpRepHom, v::GrpRepElt) -> GrpRepElt
{Return phi(v).}
  V := Domain(phi);
  W := Codomain(phi);
  require v in V : "Element should be in domain of the morphism";

  return W!(phi`morphism(V`M`M!Eltseq(v)));
end intrinsic;

intrinsic '@@'(v::GrpRepElt, phi::GrpRepHom) -> GrpRepElt
{Return a preimage of v under phi.}
  V := Domain(phi);
  W := Codomain(phi);
  require v in W : "Element should be in codomain of the morphism";

  return V!((W`M`M!Eltseq(v))@@(phi`morphism));
end intrinsic;

intrinsic '@'(v::GrpRepElt, phi::GrpRepHom) -> GrpRepElt
{Return phi(v).}
  return Evaluate(phi, v);	     
end intrinsic;

intrinsic Kernel(phi::GrpRepHom) -> GrpRep
{Returns the kernel of a homomorphism of group representations.}
  V := Domain(phi);
  B := Basis(Kernel(phi`morphism));
  return Subrepresentation(V,B);
end intrinsic;

// getGL3Contraction map returns the contraction homomorphism between Sym^a(V) \otimes
// Sym^b(V^v) and Sym^{a-1}(V) \otimes Sym^{b-1}(V^v)
// where V is the standard representation of GL3. K is the coefficient ring.

// should change it to just specify what it does on basis vectors, that's enough

function getGL3ContractionMap(a,b,K)
    assert (a gt 0) and (b gt 0); // Otherwise there is no meaning to his map (0)
    W_ab := getGL3Rep(a,b,K);
    W_minus := getGL3Rep(a-1, b-1,K);
    mon_basis := W_ab`tensor_product[1]`M`names;
    alphas := [[Degree(b, i) : i in [1..3]] : b in mon_basis];
    mon_dual_basis := W_ab`tensor_product[2]`M`names;
    betas := [[Degree(b, i) : i in [1..3]] : b in mon_dual_basis];
    coeffs := [[[alpha[i] * beta[i] : i in [1..3]] : beta in betas] : alpha in alphas];
    idxs := [[[i : i in [1..3] | coeff[i] ne 0] : coeff in coeffs_row] :
	     coeffs_row in coeffs];
    image_vecs := [[[<mon_basis[j1] div (Parent(mon_basis[j1]).i),
		     mon_dual_basis[j2] div Parent(mon_dual_basis[j2]).i> :
		     i in idxs[j1][j2]] : j2 in [1..#idxs[j1]]] : j1 in [1..#idxs]];
    sym_minus := W_minus`tensor_product[1];
    sym_dual_minus := W_minus`tensor_product[2];
    mon_basis_minus := sym_minus`M`names;
    mon_dual_basis_minus := sym_dual_minus`M`names;
    image_idxs := [[[<sym_minus.Index(mon_basis_minus, im_vec[1]),
		      sym_dual_minus.Index(mon_dual_basis_minus,im_vec[2])> :
		     im_vec in image_vecs[j1][j2]] :
		    j2 in [1..#image_vecs[j1]]] : j1 in [1..#image_vecs]];
    W_minus_image := [[[W_minus.Index(W_minus`M`names,
				      Sprintf("%o",im_idx)) :
		      im_idx in image_idxs[j1][j2]] :
		       j2 in [1..#image_idxs[j1]]] : j1 in [1..#image_idxs]];
    function get_basis_image(coeffs, idxs, W_minus_image)
	if IsEmpty(idxs) then return W_minus!0; end if;
	return &+[coeffs[idxs[i]] * W_minus_image[i] : i in [1..#idxs]];
    end function;
    basis_images := &cat [[get_basis_image(coeffs[j1][j2], idxs[j1][j2],
				      W_minus_image[j1][j2]) :
		      j2 in [1..#image_idxs[j1]]] :
			  j1 in [1..#image_idxs]];
    return Homomorphism(W_ab, W_minus, basis_images);
end function;

// getGL3HighestWeightRep - returns the highest weight representation of GL3 over K
// of highest weight (a,b,0)
// (at this point we do not consider the twist by the determinant)

intrinsic getGL3HighestWeightRep(a::RngIntElt,b::RngIntElt,K::Rng) -> GrpRep
{.}
    if (a eq 0) or (b eq 0) then return getGL3Rep(a,b,K); end if;
    return Kernel(getGL3ContractionMap(a,b,K));
end intrinsic;

intrinsic FixedSubspace(gamma::GrpMat, V::GrpRep) -> GrpRep
{Return the fixed subspace of V under the group gamma.}
//  require IsFinite(gamma) :
//		"At the moment this is only supported for finite groups";
//  char := Characteristic(BaseRing(V));
//  require (char eq 0) or (GCD(#gamma, char) eq 1) :
//    "At the moment this only works when characteristic is prime to the gro// up size";
  gamma_gens := Generators(gamma);
  if GetVerbose("AlgebraicModularForms") ge 2 then
      printf "Calculating the fixed subspace for the group gamma";
      printf " with %o generators.\n", #gamma_gens;
  end if;
  gamma_actions := [getMatrixAction(V, g) : g in gamma_gens];
  if GetVerbose("AlgebraicModularForms") ge 2 then
      printf "Calculating kernel...\n";
  end if;
  X := HorizontalJoin([Matrix(g) - 1 : g in gamma_actions]);
//  GL_V := GL(Dimension(V), BaseRing(V));
//  gamma_image := sub<GL_V | gamma_actions>;
//  trace := &+[Matrix(g) : g in gamma_image];
//  return Subrepresentation(V, Basis(Image(trace)));
  return Subrepresentation(V, Basis(Nullspace(X)));
end intrinsic;

// Here trying some things with magma built-in types
// See if it improves efficiency
// We assume g is an element in the standard representation of G
// G is the Lie group

function getActionMatrix(G, g, weight)
    std_rep := StandardRepresentation(G);
    GL_std := Codomain(std_rep);
    mats := [std_rep(x) : x in AlgebraicGenerators(G)];
    mat_grp := sub< GL_std | mats>;
    w := InverseWordMap(mat_grp)(g);
    f := hom<Parent(w) -> G | AlgebraicGenerators(G)>;
    // This does not work with GL_n, i.e.
    // GroupOfLieType(StandardRootDatum("A",2), F);
    // getting error - the integral UEA only exists for
    // semisimple Lie algebras
    // Right now this part is tailored specifically for GL_n
    if not IsSemisimple(G) then
	RootDat := RootDatum(G);
	AdRootDat := RootDatum(CartanName(RootDat));
	// This is the central weight
	ones := Vector([Rationals() | 1 : i in [1..Dimension(RootDat)]]);
	zero := Vector([Rationals()| 0 : i in [1..Dimension(AdRootDat)]]);
	A := VerticalJoin(SimpleRoots(RootDat), ones)^(-1) *
	     VerticalJoin(SimpleRoots(AdRootDat), zero);
	B := VerticalJoin(SimpleCoroots(RootDat), ones)^(-1) *
	     VerticalJoin(SimpleCoroots(AdRootDat), zero);
	phi := hom<RootDat -> AdRootDat | A, B>;
	red := GroupOfLieTypeHomomorphism(phi, BaseRing(G));
	f := f * red;
	G := GroupOfLieType(AdRootDat, BaseRing(G));
    end if;
    return HighestWeightRepresentation(G,weight)(f(w));
end function;

intrinsic FixedSubspace(gamma::GrpMat, G::GrpLie, pbMap::Map,
			weight::SeqEnum[RngIntElt]) -> ModTupFld
{Return the fixed subspace of the highest weight representation given by weight under the group gamma.}
  gamma_gens := Generators(gamma);
  gamma_actions := [getActionMatrix(G, pbMap(g), weight) : g in gamma_gens];
  X := HorizontalJoin([Matrix(g) - 1 : g in gamma_actions]);
  return Nullspace(X);
end intrinsic;

intrinsic GroupRepresentation(G::GrpLie, hw::SeqEnum[RngIntElt]) -> GrpRep
{Construct the representation of the group G with highest weight hw}
  V := New(GrpRep);
  std_rep := StandardRepresentation(G);
  GL_std := Codomain(std_rep);
  mats := [std_rep(x) : x in AlgebraicGenerators(G)];
  mat_grp := sub< GL_std | mats>;
  V`G := mat_grp;
  word_map := InverseWordMap(mat_grp);
  G_map := hom<Codomain(word_map) -> G | AlgebraicGenerators(G)>;
  if not IsSemisimple(G) then
      RootDat := RootDatum(G);
      AdRootDat := RootDatum(CartanName(RootDat));
      // This is the central weight
      ones := Vector([Rationals() | 1 : i in [1..Dimension(RootDat)]]);
      zero := Vector([Rationals()| 0 : i in [1..Dimension(AdRootDat)]]);
      A := VerticalJoin(SimpleRoots(RootDat), ones)^(-1) *
	   VerticalJoin(SimpleRoots(AdRootDat), zero);
      B := VerticalJoin(SimpleCoroots(RootDat), ones)^(-1) *
	   VerticalJoin(SimpleCoroots(AdRootDat), zero);
      phi := hom<RootDat -> AdRootDat | A, B>;
      red := GroupOfLieTypeHomomorphism(phi, BaseRing(G));
      G_map := G_map * red;
  end if;
  V`mat_to_elt := word_map * G_map;
  V`weight := HighestWeightRepresentation(Codomain(V`mat_to_elt),hw);
  
  d := DimensionOfHighestWeightModule(RootDatum(G), hw);
  names := ["v" cat IntegerToString(n) : n in [1..d]];
  V`M := CombinatorialFreeModule(BaseRing(G), names);
  V`act_mats := AssociativeArray();
  V`known_grps := [sub<mat_grp|1>];
  V`act_mats[mat_grp!1] := IdentityMatrix(BaseRing(V`M), Dimension(V`M));
  V`action_desc := Sprintf("
  function action(g, m, V)
    mat := getMatrixAction(V, g);
    return (V`M)!(Rows(Transpose(mat))[m]);
  end function;
  return action;
  ");
  V`action := eval V`action_desc;
  return V;
end intrinsic;	  
