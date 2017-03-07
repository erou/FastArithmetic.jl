module FastArithmetic

using Nemo

export monomialToDual

"""
    monomialToDual{T <: RingElem}(a::Array{T,1},P::PolyElem{T})

Convert monomial (canonical) coordinates "a" to dual coordinates
with respect to the trace generated by P.

# Remark
* a and P are over a field k which must be a perfect field ;
* P must be monic and squarefree ;
* k[x]/(P) is not necessarily a field since P is not necessarily irreducible.
"""
function monomialToDual{T <: RingElem}(a::Array{T,1},P::PolyElem{T})

  # We first check if the elements of b and coefficients
  # of P belong to the same field
  k::Nemo.Ring=parent(a[1])
  @assert k==base_ring(P)

  # We set some constants, P is of degree m and belongs to the ring R = k[t]
  m::Int64=degree(P)
  R::Nemo.Ring=parent(P)
  t::PolyElem{T}=gen(R)

  # We set Q to 1/rev(P,m+1) mod t^m
  Q::PolyElem{T}=reverse(P,m+1)
  Q=gcdinv(Q,t^m)[2]

  # Finally we compute b = rev(P'a mod P, m)Q mod t^m
  A::PolyElem{T}=R(a)
  b::PolyElem{T}=(reverse((derivative(P)*A)%P,m)*Q)%(t^m)
  return T[coeff(b,i) for i in 0:(m-1)]
end

export monomialToDual_pre
function monomialToDual_pre{T <: RingElem}(a::Array{T,1},P::PolyElem{T},TP::PolyElem{T})

  # We first check if the elements of b and coefficients
  # of P belong to the same field
  k::Nemo.Ring=parent(a[1])
  @assert k==base_ring(P)

  # We set some constants, P is of degree m and belongs to the ring R = k[t]
  m::Int64=degree(P)
  R::Nemo.Ring=parent(P)
  t::PolyElem{T}=gen(R)

  # Finally we compute b = rev(P'a mod P, m)TP mod t^m
  A::PolyElem{T}=R(a)
  b::PolyElem{T}=(reverse((derivative(P)*A)%P,m)*TP)%(t^m)
  return T[coeff(b,i) for i in 0:(m-1)]
end

export dualToMonomial

"""
    dualToMonomial{T}(b::Array{T,1},P::PolyElem{T})

Convert dual coordinates "b" to monomial coordinates with respect to the trace
generated by P.

# Remark
* a and P are over a field k which must be a perfect field ;
* P must be monic and squarefree ;
* k[x]/(P) is not necessarily a field since P is not necessarily irreducible.
"""
function dualToMonomial{T}(b::Array{T,1},P::PolyElem{T})

  # We first check if the elements of b and coefficients
  # of P belong to the same field
  k::Nemo.Ring=parent(b[1])
  @assert k==base_ring(P)


  # We set some constants, P is of degree m and belongs to the ring R = k[t]
  m::Int64=degree(P)
  R::Nemo.Ring=parent(P)
  t::PolyElem{T}=gen(R)

  # We compute S = 1/P' mod P, c = rev(P, m+1)b, d = cS mod P
  S::PolyElem{T}=gcdinv(derivative(P),P)[2]
  c::PolyElem{T}=(reverse(P,m+1)*R(b))%(t^m)
  c=reverse(c,m)
  d::PolyElem{T}=(c*S)%P
  return T[coeff(d,i) for i in 0:(m-1)]
end

export dualToMonomial_pre
function dualToMonomial_pre{T}(b::Array{T,1},P::PolyElem{T}, S::PolyElem{T})

  # We first check if the elements of b and coefficients
  # of P belong to the same field
  k::Nemo.Ring=parent(b[1])
  @assert k==base_ring(P)


  # We set some constants, P is of degree m and belongs to the ring R = k[t]
  m::Int64=degree(P)
  R::Nemo.Ring=parent(P)
  t::PolyElem{T}=gen(R)

  # We compute S = 1/P' mod P, c = rev(P, m+1)b, d = cS mod P
  c::PolyElem{T}=(reverse(P,m+1)*R(b))%(t^m)
  c=reverse(c,m)
  d::PolyElem{T}=(c*S)%P
  return T[coeff(d,i) for i in 0:(m-1)]
end

export mulT

"""
    mulT{T}(c::Array{T,1},P::PolyElem{T},n::Int64)

The tranposition of the naive algorithm of multiplication by P.

# Arguments
* c::Array{T,1} must have length m (degree of P) + n.

# Remark
* closely linked with the middle product [1] ;
* I don't really see why n is an argument, since we could obtain it by
computing n = length(c) - degree(P).

# References
* [1] : G. Hanrot, M. Quercia, and P. Zimmerman. The middle product algorithm I.
Appl. Algebra Engrg. Comm. Comput., 14(6):415-438, 2004.
"""
function mulT{T}(c::Array{T,1},P::PolyElem{T},n::Int64)
    
  # We first check if the elements of b and coefficients
  # of P belong to the same field
  m::Int64=degree(P)
  k::Nemo.Ring=base_ring(P)
  @assert k==parent(c[1])

  # We compute R = k[t]
  R::Nemo.Ring=parent(P)
  t::PolyElem{T}=gen(R)

  # And we transpose all the basic operations
  p::Array{T,1}=T[k(coeff(P,j)) for j in 0:m]
  b::Array{T,1}=Array(T,n+1) # array filled with "#undef"
  for i in 1:(n+1)
    b[i]=k(0)
  end
  for i in range(m+n,-1,m+n+1)
    for j in range(min(m,i),-1,min(m,i)-max(0,i-n)+1)
      b[i-j+1]=b[i-j+1]+p[j+1]*c[i+1]
    end
  end
  return R(T[b[i] for i in 1:(n+1)])
end

export mulTmid

"""
    mulTmid{T}(c::Array{T,1},P::PolyElem{T},n::Int64)

The tranposition of the algorithm of multiplication by P. Using middle product.

# Arguments
* c::Array{T,1} must have length m (degree of P) + n + 1 since 
  it represents a polynomial in R_{n+m}[X].

# Remark
* the middle product formula is in [1]
* mulTmid(⋅,P,n) : R_{n+m}[X] ⟶ R_n[X]

# References
* [1] : G. Hanrot, M. Quercia, and P. Zimmerman. The middle product algorithm I.
Appl. Algebra Engrg. Comm. Comput., 14(6):415-438, 2004.
"""
function mulTmid{T}(c::Array{T,1},P::PolyElem{T},n::Int64)

  # We first check if the elements of b and coefficients
  # of P belong to the same ring
  m::Int64=degree(P)
  k::Nemo.Ring=base_ring(P)
  @assert k==parent(c[1])

  # And we compute the middle product of P and c
  R::Nemo.Ring=parent(P)
  C::PolyElem{T}=R(c)
  Q::PolyElem{T}=reverse(P,m+1)
  return shift_right(mullow(Q,C,n+m+1),m)
end

export remT

"""
    remT{T}(r::Array{T,1},P::PolyElem{T},n::Int64)

Transposition of the remainder by P algorithm.

An other linear extension algorithm. Take the r first values of a linear
recurring sequence of minimal polynomial P and compute the n first values.
"""
function remT{T}(r::Array{T,1},P::PolyElem{T},n::Int64)

  # We first check if the elements of b and coefficients
  # of P belong to the same ring
  m::Int64=degree(P)
  k::Nemo.Ring=base_ring(P)
  @assert k==parent(r[1])

  # We compute the ring K = k[t]
  K::Nemo.Ring=parent(P)
  t::PolyElem{T}=gen(K)

  # We compute α = 1/rev(P, m+1) mod t^(n-m)
  R::PolyElem{T}=K(T[r[i] for i in 1:m]) # useless creation of a list... memory !
  α::PolyElem{T}=reverse(P,m+1)
  α=gcdinv(α,t^(n-m))[2]

  # We add zeros to match the awaited size
  b::Array{T,1}=copy(r) # copy + push! : cost ?
  while length(b)<n
    push!(b,k(0))
  end

  # We compute the final result
  ans = R-shift_left((mullow(α,mulTmid(b,P,n-m),n-m)),m)
  return T[coeff(ans,j) for j in 0:n-1]
end

export remT_pre
function remT_pre{T}(r::Array{T,1},P::PolyElem{T},n::Int64,TP::PolyElem{T})

  # We first check if the elements of b and coefficients
  # of P belong to the same ring
  m::Int64=degree(P)
  k::Nemo.Ring=base_ring(P)
  @assert k==parent(r[1])

  # We compute the ring K = k[t]
  K::Nemo.Ring=parent(P)
  t::PolyElem{T}=gen(K)

  # We compute α = 1/rev(P, m+1) mod t^(n-m)
  R::PolyElem{T}=K(T[r[i] for i in 1:m]) # useless creation of a list... memory !
  α::PolyElem{T}=TP % t^(n-m)

  # We add zeros to match the awaited size
  b::Array{T,1}=copy(r) # copy + push! : cost ?
  while length(b)<n
    push!(b,k(0))
  end

  # We compute the final result
  ans = R-shift_left((mullow(α,mulTmid(b,P,n-m),n-m)),m)
  return T[coeff(ans,j) for j in 0:n-1]
end


export remTnaif

"""
    remTnaif{T}(r::Array{T,1},P::PolyElem{T},n::Int64)

Linear extension algorithm.

Take the m first elements of a Linear recurring sequence with minimal
polynomial P and compute the n first.
"""
function remTnaif{T}(r::Array{T,1},P::PolyElem{T},n::Int64)
  m::Int64=degree(P)
  p::Array{T,1}=T[coeff(P,j) for j in 0:m]
  b::Array{T,1}=copy(r)
  while length(b)<n
      s=sum([-1*p[j]*b[end-m+j] for j in 1:m])
      push!(b,p[end]^(-1)*s)
  end
  return b
end

export mulModT

"""
    mulModT{T}(P::Array{T,1},Q::PolyElem{T},R::PolyElem{T},n::Int64)

Transposition of the modular multiplication.

# Arguments
* P::Array{T,1} represents a polynomial of degree r - 1, so is of size r (where r=deg(R)) ;
* Q::PolyElem{T} is the fixed polynomial used in mul(⋅,Q) : P ⟼ PQ ;
* R::PolyElem{T} is the polynomial used in the remainder rem(⋅,R) : P ⟼ P mod R ;
* n::Int64 is the degree of the output (at most).

# Remark
* mulModT(⋅,Q,R,n) : R_{r-1}[X] ⟶ R_n[X].
"""
function mulModT{T}(P::Array{T,1},Q::PolyElem{T},R::PolyElem{T},n::Int64)
  q,r=degree(Q),degree(R)
  a = remT(P,R,n+q+1)
  return mulTmid(a,Q,n)
end

export embed

"""
    embed{T}(b::Array{T,1},P::PolyElem{T},c::Array{T,1},Q::PolyElem{T},r::Int64=0)

Compute the embeding of Π={bc | b ∈ k[x]/(P) , c ∈ k[y]/(Q)} ⊂ k[x,y]/(P,Q) in k[z]/(R).
"""
function embed{T}(b::Array{T,1},P::PolyElem{T},c::Array{T,1},Q::PolyElem{T},r::Int64=0)
  if r==0
    r=length(b)*length(c)
  end
  t::Array{T,1}=remT(b,P,r)
  u::Array{T,1}=remT(c,Q,r)
  return T[t[j]*u[j] for j in 1:r]
end

export berlekampMassey

"""
    berlekampMassey{T <: RingElem}(a::Array{T,1},n::Int64,S=0)

Compute the minimal polynomial of a linear recurring sequence.
"""
function berlekampMassey{T <: RingElem}(a::Array{T,1},n::Int64,S=0)
  if S==0
    k::Nemo.Ring=parent(a[1])
    S::Nemo.Ring,x::PolyElem{T}=PolynomialRing(k,"x")
  else
    x=gen(S)
  end
  m::Int64=2*n-1
  R0::PolyElem{T}=x^(2*n)
  R1::PolyElem{T}=S(reverse(a))
  V0::PolyElem{T}=S(0)
  V1::PolyElem{T}=S(1)
  while n<=degree(R1)
    Q::PolyElem{T},R::PolyElem{T}=divrem(R0,R1)
    V::PolyElem{T}=V0-Q*V1
    V0=V1
    V1=V
    R0=R1
    R1=R
  end
  return V1*lead(V1)^(-1)
end

export computeR

"""
    computeR{T}(P::PolyElem{T},Q::PolyElem{T})

Compute the composed product R of P and Q.
"""
function computeR{T}(P::PolyElem{T},Q::PolyElem{T})
  m::Int64=degree(P)
  n::Int64=degree(Q)
  k::Nemo.Ring=base_ring(P)

  up::Array{T,1}=monomialToDual([k(1)],P)
  uq::Array{T,1}=monomialToDual([k(1)],Q)

  t::Array{T,1}=embed(up,P,uq,Q,2*m*n)

  return berlekampMassey(t,m*n,parent(P))
end

export project

"""
    project{T}(a::Array{T,1},P::PolyElem{T},Q::PolyElem{T})

Compute the section of the embedding k[x]/(P) ⟶ k[z]/(R), where R = P ⊙ Q.
"""
function project{T}(a::Array{T,1},P::PolyElem{T},Q::PolyElem{T})
  n::Int64=degree(Q)
  m::Int64=degree(P)
  c::Array{T,1}=Array(T,n)
  k::Nemo.Ring=base_ring(Q)
  c[1]=k(1)
  for j in 2:n
    c[j]=k(0)
  end
  u::Array{T,1}=remT(c,Q,m*n) # it seems to be the only thing expensive
  K::Nemo.Ring=parent(P)
  d::PolyElem{T}=K([a[j]*u[j] for j in 1:(m*n)])%P
  return T[coeff(d,j) for j in 0:(m-1)]
end

export phi1

"""
    phi1{T}(b::Array{T,2},P::PolyElem{T},Q::PolyElem{T})

Compute the isomorphism Φ : k[x,y]/(P,Q) ⟶ k[z]/(R).

# Arguments
* b::Array{T,2} is a 2d array reprenting (b_ji) where 0 <= i < m and 0 <= j < n, it is
the transpose of the b_ij of the paper because we prefer to extract columns than lines for
types reasons.
"""
function phi1{T}(b::Array{T,2},P::PolyElem{T},Q::PolyElem{T})
  k::Nemo.Ring=parent(b[1,1])
  @assert k==base_ring(Q)
  m::Int64=degree(P)
  n::Int64=degree(Q)
  u::Array{T,1}=remT(monomialToDual(T[k(1)],P),P,m*(n+1)-1)
  a::Array{T,1}=Array(T,m*n)
  for j in 1:m*n
    a[j]=k(0)
  end
  for i in 1:m
    t::Array{T,1}=remT(b[:,i],Q,m*n)
    for j in 1:m*n
      a[j]=a[j]+t[j]*u[i+j-1] # /!\ indices
    end
  end
  return a
end

export phi1_pre
function phi1_pre{T}(b::Array{T,2},P::PolyElem{T},Q::PolyElem{T}, up::Array{T,1})
  k::Nemo.Ring=parent(b[1,1])
  @assert k==base_ring(Q)
  m::Int64=degree(P)
  n::Int64=degree(Q)
  u::Array{T,1}=remT(up,P,m*(n+1)-1)
  a::Array{T,1}=Array(T,m*n)
  for j in 1:m*n
    a[j]=k(0)
  end
  for i in 1:m
    t::Array{T,1}=remT(b[:,i],Q,m*n)
    for j in 1:m*n
      a[j]=a[j]+t[j]*u[i+j-1] # /!\ indices
    end
  end
  return a
end

export inversePhi1

"""
    inversePhi1{T}(a::Array{T,1},P::PolyElem{T},Q::PolyElem{T})

Compute Φ^(-1) : k[z]/(R) ⟶ k[x,y]/(P,Q).

# Output
* b::Array{T,2} is a 2d array reprenting (b_ji) where 0 <= i < m and 0 <= j < n, it is
the transpose of the b_ij of the paper because we prefer to extract columns than lines for
types reasons.
"""
function inversePhi1{T}(a::Array{T,1},P::PolyElem{T},Q::PolyElem{T})
  k::Nemo.Ring=parent(a[1,1])
  @assert k==base_ring(Q)
  K::Nemo.Ring=parent(Q)
  y::PolyElem{T}=gen(K)
  m::Int64=degree(P)
  n::Int64=degree(Q)
  b::Array{T,2}=Array(T,(n,m))
  u::Array{T,1}=remT(monomialToDual(T[k(1)],P),P,m*(n+1)-1)
  for i in m:-1:1
    d::PolyElem{T}=K([a[j]*u[i+j-1] for j in 1:(m*n)])%Q
    for j in 1:n
    b[j,i]=coeff(d,j-1)
    end
  end
  return b
end

export inversePhi1_pre
function inversePhi1_pre{T}(a::Array{T,1},P::PolyElem{T},Q::PolyElem{T}, up::Array{T,1})
  k::Nemo.Ring=parent(a[1,1])
  @assert k==base_ring(Q)
  K::Nemo.Ring=parent(Q)
  y::PolyElem{T}=gen(K)
  m::Int64=degree(P)
  n::Int64=degree(Q)
  b::Array{T,2}=Array(T,(n,m))
  u::Array{T,1}=remT(up,P,m*(n+1)-1)
  for i in m:-1:1
    d::PolyElem{T}=K([a[j]*u[i+j-1] for j in 1:(m*n)])%Q
    for j in 1:n
    b[j,i]=coeff(d,j-1)
    end
  end
  return b
end

export phi2

"""
    phi2{T}(b::Array{T,2},P::PolyElem{T},Q::PolyElem{T})

Compute the isomorphism Φ : k[x,y]/(P,Q) ⟶ k[z]/(R).

# Argument
* This time b::Array{T,2} is the same as the one in the text.
"""
function phi2{T,Y}(b::Array{T,2},P::Y,Q::Y,R::Y)
  k::Nemo.Ring=parent(b[1,1])
  @assert k==base_ring(P)
  K::Nemo.Ring=parent(P)
  z=gen(K)
  m::Int64=degree(P)
  n::Int64=degree(Q)
  N::Int64=n+m-1
  p::Int64=ceil(sqrt(N))
  q::Int64=ceil(N/p)
  y::Array{T,1}=monomialToDual(T[k(0),k(1)],Q)
  up::Array{T,1}=monomialToDual(T[k(1)],P)
  S::Y=K(dualToMonomial(embed(up,P,y,Q),R))
  U::Y=gcdinv(S,R)[2]

  Sprime::Array{Y,1}=Array(Y,q+1)
  Sprime[1]=K(1)

  for i in 2:(q+1)
    Sprime[i]=mulmod(Sprime[i-1],S,R)
  end

  MT::Nemo.Ring=MatrixSpace(K,q,n)
  mt::MatElem=MT()

  for i in 1:q
    c::Array{T,1}=T[coeff(Sprime[i],h) for h in 0:(m*n-1)]
    for j in 1:n
      mt[i,j]=K(c[(j-1)*m+1:j*m])
    end
  end

  MC::Nemo.Ring=MatrixSpace(K,p,q)
  mc::MatElem=MC()

  for i in 1:p
    for j in 1:q
      mc[i,j]=K(T[h+i*q+j-m-2 < 1 ? k(0) : h+i*q+j-m-2 > n ? k(0) : b[h,h+i*q+j-m-2] for h in 1:m])
    end
  end

  Mv::MatElem=mc*mt

  V::Array{Y,1}=Array(Y,p)
  for i in 1:p
    V[i]=sum([shift_left(Mv[i,j],(j-1)*m) for j in 1:n])%R
  end

  a::Y=K()

  for i in p:-1:1
    a=(Sprime[q+1]*a+V[i])%R
  end

  a=mulmod(a,U^(m-1),R)

  return T[coeff(a,i) for i in 0:(m*n-1)]
end

export phi2_pre
function phi2_pre{T,Y}(b::Array{T,2},P::Y,Q::Y,R::Y, up::Array{T,1})
  k::Nemo.Ring=parent(b[1,1])
  @assert k==base_ring(P)
  K::Nemo.Ring=parent(P)
  z=gen(K)
  m::Int64=degree(P)
  n::Int64=degree(Q)
  N::Int64=n+m-1
  p::Int64=ceil(sqrt(N))
  q::Int64=ceil(N/p)
  y::Array{T,1}=monomialToDual(T[k(0),k(1)],Q)
  S::Y=K(dualToMonomial(embed(up,P,y,Q),R))
  U::Y=gcdinv(S,R)[2]

  Sprime::Array{Y,1}=Array(Y,q+1)
  Sprime[1]=K(1)

  for i in 2:(q+1)
    Sprime[i]=mulmod(Sprime[i-1],S,R)
  end

  MT::Nemo.Ring=MatrixSpace(K,q,n)
  mt::MatElem=MT()

  for i in 1:q
    c::Array{T,1}=T[coeff(Sprime[i],h) for h in 0:(m*n-1)]
    for j in 1:n
      mt[i,j]=K(c[(j-1)*m+1:j*m])
    end
  end

  MC::Nemo.Ring=MatrixSpace(K,p,q)
  mc::MatElem=MC()

  for i in 1:p
    for j in 1:q
      mc[i,j]=K(T[h+i*q+j-m-2 < 1 ? k(0) : h+i*q+j-m-2 > n ? k(0) : b[h,h+i*q+j-m-2] for h in 1:m])
    end
  end

  Mv::MatElem=mc*mt

  V::Array{Y,1}=Array(Y,p)
  for i in 1:p
    V[i]=sum([shift_left(Mv[i,j],(j-1)*m) for j in 1:n])%R
  end

  a::Y=K()

  for i in p:-1:1
    a=(Sprime[q+1]*a+V[i])%R
  end

  a=mulmod(a,U^(m-1),R)

  return T[coeff(a,i) for i in 0:(m*n-1)]
end

export inversePhi2

"""
    inversePhi2{T}(a::Array{T,1},P::Y,Q::Y)

Compute Φ^(-1) : k[z]/(R) ⟶ k[x,y]/(P,Q).

# Output
* This time b::Array{T,2} is the same as the one in the text.
"""
function inversePhi2{T,Y}(a::Array{T,1},P::Y,Q::Y,R::Y)
  k::Nemo.Ring=parent(a[1])
  @assert k==base_ring(P)
  K::Nemo.Ring=parent(P)
  m::Int64=degree(P)
  n::Int64=degree(Q)
  N::Int64=n+m-1
  p::Int64=ceil(sqrt(N))
  q::Int64=ceil(N/p)
  y::Array{T,1}=monomialToDual(T[k(0),k(1)],Q)
  up::Array{T,1}=monomialToDual(T[k(1)],P)
  S::Y=K(dualToMonomial(embed(up,P,y,Q),R))
  U::Y=gcdinv(S,R)[2]

  Sprime::Array{Y,1}=Array(Y,q+1)
  Sprime[1]=K(1)

  for i in 2:(q+1)
    Sprime[i]=mulmod(Sprime[i-1],S,R)
  end

  MT::Nemo.Ring=MatrixSpace(K,n,q)
  mt::MatElem=MT()

  for i in 1:q
    c::Array{T,1}=T[coeff(Sprime[i],h) for h in 0:(m*n-1)]
    for j in 1:n
      mt[j,i]=reverse(K(c[(j-1)*m+1:j*m]),m) # reverse in order to do transposed product
    end
  end

  u::Y=powmod(U,m-1,R)
  W::Y=mulTmid(remT(a,R,2*m*n-1),u,m*n-1)
  a=T[coeff(W,j) for j in 0:(m*n-1)]

  V::Array{Array{T,1},1}=Array(Array{T,1},p)
  A::Y=K()


  for i in 1:p
    V[i]=remT(a,R,m*n+m-1)
    A=mulTmid(remT(a,R,2*m*n-1),Sprime[q+1],m*n-1) # That's the thing taking time !!!
    a=T[coeff(A,j) for j in 0:(m*n-1)]
  end

  MV::Nemo.Ring=MatrixSpace(K,p,n)
  mv::MatElem=MV()

  for i in 1:p, j in 1:n
    mv[i,j]=K(V[i][(j-1)*m+1:(j-1)*m+2*m-1])
  end

  mc::MatElem=mv*mt
  cc::Array{Y,1}=Array(Y,p*q)

  for i in 1:p, j in 1:q
    cc[(i-1)*q+j]=shift_right(truncate(mc[i,j],2*m-1),m-1)
  end

  return T[coeff(cc[j-i+m],i-1) for i in 1:m, j in 1:n]
end

export inversePhi2_pre
function inversePhi2_pre{T,Y}(a::Array{T,1},P::Y,Q::Y,R::Y,up::Array{T,1})
  k::Nemo.Ring=parent(a[1])
  @assert k==base_ring(P)
  K::Nemo.Ring=parent(P)
  m::Int64=degree(P)
  n::Int64=degree(Q)
  N::Int64=n+m-1
  p::Int64=ceil(sqrt(N))
  q::Int64=ceil(N/p)
  y::Array{T,1}=monomialToDual(T[k(0),k(1)],Q)
  S::Y=K(dualToMonomial(embed(up,P,y,Q),R))
  U::Y=gcdinv(S,R)[2]

  Sprime::Array{Y,1}=Array(Y,q+1)
  Sprime[1]=K(1)

  for i in 2:(q+1)
    Sprime[i]=mulmod(Sprime[i-1],S,R)
  end

  MT::Nemo.Ring=MatrixSpace(K,n,q)
  mt::MatElem=MT()

  for i in 1:q
    c::Array{T,1}=T[coeff(Sprime[i],h) for h in 0:(m*n-1)]
    for j in 1:n
      mt[j,i]=reverse(K(c[(j-1)*m+1:j*m]),m) # reverse in order to do transposed product
    end
  end

  u::Y=powmod(U,m-1,R)
  W::Y=mulTmid(remT(a,R,2*m*n-1),u,m*n-1)
  a=T[coeff(W,j) for j in 0:(m*n-1)]

  V::Array{Array{T,1},1}=Array(Array{T,1},p)
  A::Y=K()


  for i in 1:p
    V[i]=remT(a,R,m*n+m-1)
    A=mulTmid(remT(a,R,2*m*n-1),Sprime[q+1],m*n-1) # That's the thing taking time !!!
    a=T[coeff(A,j) for j in 0:(m*n-1)]
  end

  MV::Nemo.Ring=MatrixSpace(K,p,n)
  mv::MatElem=MV()

  for i in 1:p, j in 1:n
    mv[i,j]=K(V[i][(j-1)*m+1:(j-1)*m+2*m-1])
  end

  mc::MatElem=mv*mt
  cc::Array{Y,1}=Array(Y,p*q)

  for i in 1:p, j in 1:q
    cc[(i-1)*q+j]=shift_right(truncate(mc[i,j],2*m-1),m-1)
  end

  return T[coeff(cc[j-i+m],i-1) for i in 1:m, j in 1:n]
end

println("FastArithmetic comes with even less warranty\n")

end
