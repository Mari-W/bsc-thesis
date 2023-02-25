-- [latex] prefix(F)
-- [latex] hide
{-# OPTIONS --allow-unsolved-metas #-}
open import Data.Unit using (⊤; tt)
open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_; _++_; drop)
open import Data.List.Relation.Unary.Any using (here; there)
open import Data.List.Membership.Propositional using (_∈_)
open import Data.Sum.Base using (_⊎_; inj₁; inj₂)
open import Data.Product using (_×_; _,_; Σ-syntax; ∃-syntax)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; subst; sym; cong; cong₂; trans; module ≡-Reasoning)
open import Function using (id; _∘_)
open ≡-Reasoning

module SystemF where

-- Sorts --------------------------------------------------------------------------------

data Ctxable : Set where
  ⊤ᶜ : Ctxable
  ⊥ᶜ : Ctxable

-- [latex] block(Sort)

data Sort : Ctxable → Set where
  eₛ  : Sort ⊤ᶜ
  τₛ  : Sort ⊤ᶜ
  κₛ  : Sort ⊥ᶜ

Sorts : Set
Sorts = List (Sort ⊤ᶜ)

-- [latex] hide

infix 25 _▷_ _▷▷_
pattern _▷_ xs x = x ∷ xs
_▷▷_ : {A : Set} → List A → List A → List A
xs ▷▷ ys = ys ++ xs

variable
  r r' r'' r₁ r₂ : Ctxable
  s s' s'' s₁ s₂ : Sort r
  S S' S'' S₁ S₂ : Sorts
  x x' x'' x₁ x₂ : eₛ ∈ S
  α α' α'' α₁ α₂ : τₛ ∈ S

-- Syntax -------------------------------------------------------------------------------

infixr 4 λ`x→_ Λ`α→_ let`x=_`in_ ∀`α_
infixr 5 _⇒_ _·_ _•_
infix  6 `_ 

-- [latex] block(Term)

data Term : Sorts → Sort r → Set where
  `_           : s ∈ S → Term S s
  tt           : Term S eₛ
  λ`x→_        : Term (S ▷ eₛ) eₛ → Term S eₛ
  Λ`α→_        : Term (S ▷ τₛ) eₛ → Term S eₛ
  _·_          : Term S eₛ → Term S eₛ → Term S eₛ
  _•_          : Term S eₛ → Term S τₛ → Term S eₛ
  let`x=_`in_  : Term S eₛ → Term (S ▷ eₛ) eₛ → Term S eₛ
  `⊤           : Term S τₛ
  _⇒_          : Term S τₛ → Term S τₛ → Term S τₛ
  ∀`α_         : Term (S ▷ τₛ) τₛ → Term S τₛ
  ⋆            : Term S κₛ

-- [latex] hide
Var : Sorts → Sort ⊤ᶜ → Set
-- [latex] inline(Var)
Var S s = s ∈ S 

-- [latex] hide
Expr : Sorts → Set
-- [latex] inline(Expr)
Expr S = Term S eₛ

-- [latex] hide
Type : Sorts → Set
-- [latex] inline(Type)
Type S = Term S τₛ

-- [latex] hide

variable
  t t' t'' t₁ t₂ : Term S s
  e e' e'' e₁ e₂ : Expr S
  τ τ' τ'' τ₁ τ₂ : Type S

-- Renaming -----------------------------------------------------------------------------

-- [latex] block(Ren)

Ren : Sorts → Sorts → Set
Ren S₁ S₂ = ∀ {s} → Var S₁ s → Var S₂ s

-- [latex] hide

idᵣ : Ren S S
idᵣ = id

wkᵣ : Ren S (S ▷ s) 
wkᵣ = there

-- [latex] inline(renext)
extᵣ : Ren S₁ S₂ → Ren (S₁ ▷ s) (S₂ ▷ s)
-- [latex] hide
extᵣ ρ (here refl) = here refl
extᵣ ρ (there x) = there (ρ x)

dropᵣ : Ren S₁ S₂ → Ren S₁ (S₂ ▷ s) 
dropᵣ ρ x = there (ρ x)

-- [latex] block(ren)

ren : Ren S₁ S₂ → (Term S₁ s → Term S₂ s)
ren ρ (` x) = ` (ρ x)
ren ρ tt = tt
ren ρ (λ`x→ e) = λ`x→ (ren (extᵣ ρ) e)
ren ρ (Λ`α→ e) = Λ`α→ (ren (extᵣ ρ) e)
ren ρ (e₁ · e₂) = (ren ρ e₁) · (ren ρ e₂)
ren ρ (e • τ) = (ren ρ e) • (ren ρ τ)
ren ρ (let`x= e₂ `in e₁) = let`x= (ren ρ e₂) `in ren (extᵣ ρ) e₁
ren ρ `⊤ = `⊤
ren ρ (τ₁ ⇒ τ₂) = ren ρ τ₁ ⇒ ren ρ τ₂
ren ρ (∀`α τ) = ∀`α (ren (extᵣ ρ) τ)
ren ρ ⋆ = ⋆

-- [latex] block(wk)

wk : Term S s → Term (S ▷ s') s
wk = ren there

-- [latex] hide

variable
  ρ ρ' ρ'' ρ₁ ρ₂ : Ren S₁ S₂

-- Substitution -------------------------------------------------------------------------

-- [latex] block(Sub)

Sub : Sorts → Sorts → Set
Sub S₁ S₂ = ∀ {s} → Var S₁ s → Term S₂ s

-- [latex] hide

idₛ : Sub S S
-- [latex] inline(idsub)
idₛ = `_
-- [latex] hide

extₛ : Sub S₁ S₂ → Sub (S₁ ▷ s) (S₂ ▷ s)
extₛ σ (here refl) = ` here refl
extₛ σ (there x) = ren wkᵣ (σ x)

dropₛ : Sub S₁ S₂ → Sub S₁ (S₂ ▷ s) 
dropₛ σ x = wk (σ x)

-- [latex] inline(singlesub)
singleₛ : Sub S₁ S₂ → Term S₂ s → Sub (S₁ ▷ s) S₂
-- [latex] hide
singleₛ σ t (here refl) = t
singleₛ σ t (there x) = σ x

-- [latex] inline(sub)
sub : Sub S₁ S₂ → (Term S₁ s → Term S₂ s)
-- [latex] hide
sub σ (` x) = (σ x)
sub σ tt = tt
sub σ (λ`x→ e) = λ`x→ (sub (extₛ σ) e)
sub σ (Λ`α→ e) = Λ`α→ (sub (extₛ σ) e)
sub σ (e₁ · e₂) = sub σ e₁ · sub σ e₂
sub σ (e • τ) = sub σ e • sub σ τ
sub σ (let`x= e₂ `in e₁) = let`x= sub σ e₂ `in (sub (extₛ σ) e₁)
sub σ `⊤ = `⊤
sub σ (τ₁ ⇒ τ₂) = sub σ τ₁ ⇒ sub σ τ₂
sub σ (∀`α τ) = ∀`α (sub (extₛ σ) τ)
sub σ ⋆ = ⋆

-- [latex] block(subs)

_[_] : Term (S ▷ s') s → Term S s' → Term S s
t [ t' ] = sub (singleₛ idₛ t') t

-- [latex] block(hide)

variable
  σ σ' σ'' σ₁ σ₂ : Sub S₁ S₂ 

-- Context ------------------------------------------------------------------------------

kind-ctxable : Sort ⊤ᶜ → Ctxable
kind-ctxable eₛ = ⊤ᶜ
kind-ctxable τₛ = ⊥ᶜ


kind-of : (s : Sort ⊤ᶜ) → Sort (kind-ctxable s)
-- [latex] block(kind)
kind-of eₛ = τₛ
kind-of τₛ = κₛ

-- [latex] hide

variable 
  T T' T'' T₁ T₂ : Term S (kind-of s)

-- [latex] block(Ctx)

data Ctx : Sorts → Set where
  ∅   : Ctx []
  _▶_ : Ctx S → Term S (kind-of s) → Ctx (S ▷ s)

-- [latex] inline(lookup)
lookup : Ctx S → Var S s → Term S (kind-of s) 
-- [latex] hide
lookup (Γ ▶ T) (here refl) = wk T
lookup (Γ ▶ T) (there x) = wk (lookup Γ x)

-- [latex] hide

variable 
  Γ Γ' Γ'' Γ₁ Γ₂ : Ctx S

-- Typing -------------------------------------------------------------------------------

-- Expression Typing

infix 3 _⊢_∶_
-- [latex] block(Typing)
data _⊢_∶_ : Ctx S → Term S s → Term S (kind-of s) → Set where
  ⊢`x :  
    lookup Γ x ≡ τ →
    Γ ⊢ ` x ∶ τ
  ⊢⊤ : 
    Γ ⊢ tt ∶ `⊤
  ⊢λ : 
    Γ ▶ τ ⊢ e ∶ wk τ' →  
    Γ ⊢ λ`x→ e ∶ τ ⇒ τ' 
  ⊢Λ : 
    Γ ▶ ⋆ ⊢ e ∶ τ →  
    Γ ⊢ Λ`α→ e ∶ ∀`α τ
  ⊢· : 
    Γ ⊢ e₁ ∶ τ₁ ⇒ τ₂ →
    Γ ⊢ e₂ ∶ τ₁ →
    Γ ⊢ e₁ · e₂ ∶ τ₂
  ⊢• : 
    Γ ⊢ e ∶ ∀`α τ' →
    Γ ⊢ e • τ ∶ τ' [ τ ]
  ⊢let : 
    Γ ⊢ e₂ ∶ τ →
    Γ ▶ τ ⊢ e₁ ∶ wk τ' →
    Γ ⊢ let`x= e₂ `in e₁ ∶ τ'
  ⊢τ :
    Γ ⊢ τ ∶ ⋆

-- [latex] hide

-- Renaming Typing

infix 3 _∶_⇒ᵣ_
-- [latex] block(RenTyping)
data _∶_⇒ᵣ_ : Ren S₁ S₂ → Ctx S₁ → Ctx S₂ → Set where
  ⊢idᵣ : ∀ {Γ} → _∶_⇒ᵣ_ {S₁ = S} {S₂ = S} idᵣ Γ Γ
  ⊢extᵣ : ∀ {ρ : Ren S₁ S₂} {Γ₁ : Ctx S₁} {Γ₂ : Ctx S₂} {T' : Term S₁ (kind-of s)} → 
    ρ ∶ Γ₁ ⇒ᵣ Γ₂ →
    (extᵣ ρ) ∶ (Γ₁ ▶ T') ⇒ᵣ (Γ₂ ▶ ren ρ T')
  ⊢dropᵣ : ∀ {ρ : Ren S₁ S₂} {Γ₁ : Ctx S₁} {Γ₂ : Ctx S₂} {T' : Term S₂ (kind-of s)} →
    ρ ∶ Γ₁  ⇒ᵣ Γ₂ →
    (dropᵣ ρ) ∶ Γ₁ ⇒ᵣ (Γ₂ ▶ T')

-- [latex] hide

⊢wkᵣ : ∀ {T : Term S (kind-of s)} → (dropᵣ idᵣ) ∶ Γ ⇒ᵣ (Γ ▶ T)
⊢wkᵣ = ⊢dropᵣ ⊢idᵣ


-- [latex] block(SubTyping)

_∶_⇒ₛ_ : Sub S₁ S₂ → Ctx S₁ → Ctx S₂ → Set
_∶_⇒ₛ_ {S₁ = S₁} σ Γ₁ Γ₂ = ∀ {s} (x : Var S₁ s) → Γ₂ ⊢ σ x ∶ (sub σ (lookup Γ₁ x))

-- [latex] hide

extₛidₛ≡idₛ : ∀ (x : Var (S ▷ s') s) → extₛ idₛ x ≡ idₛ x
extₛidₛ≡idₛ (here refl) = refl
extₛidₛ≡idₛ (there x) = refl 

⊢ext-σ₁≡ext-σ₂ : ∀ {σ₁ σ₂ : Sub S₁ S₂} → 
 (∀ {s} (x : Var S₁ s) → σ₁ x ≡ σ₂ x) → 
 (∀ {s} (x : Var (S₁ ▷ s') s) → (extₛ σ₁) x ≡ (extₛ σ₂) x)
⊢ext-σ₁≡ext-σ₂ σ₁≡σ₂ (here refl) = refl
⊢ext-σ₁≡ext-σ₂ σ₁≡σ₂ (there x) = cong wk (σ₁≡σ₂ x)

σ₁≡σ₂→σ₁τ≡σ₂τ : ∀ {σ₁ σ₂ : Sub S₁ S₂} (τ : Type S₁) → 
  (∀ {s} (x : Var S₁ s) → σ₁ x ≡ σ₂ x) → 
  sub σ₁ τ ≡ sub σ₂ τ
σ₁≡σ₂→σ₁τ≡σ₂τ (` x) σ₁≡σ₂ = σ₁≡σ₂ x
σ₁≡σ₂→σ₁τ≡σ₂τ `⊤ σ₁≡σ₂ = refl
σ₁≡σ₂→σ₁τ≡σ₂τ (τ₁ ⇒ τ₂) σ₁≡σ₂ = cong₂ _⇒_ (σ₁≡σ₂→σ₁τ≡σ₂τ τ₁ σ₁≡σ₂) (σ₁≡σ₂→σ₁τ≡σ₂τ τ₂ σ₁≡σ₂)
σ₁≡σ₂→σ₁τ≡σ₂τ (∀`α τ) σ₁≡σ₂ = cong ∀`α_ (σ₁≡σ₂→σ₁τ≡σ₂τ τ (⊢ext-σ₁≡ext-σ₂ σ₁≡σ₂))

idₛτ≡τ : (τ : Type S) →
  sub idₛ τ ≡ τ
idₛτ≡τ (` x) = refl
idₛτ≡τ `⊤ = refl
idₛτ≡τ (τ₁ ⇒ τ₂) = cong₂ _⇒_ (idₛτ≡τ τ₁) (idₛτ≡τ τ₂)
idₛτ≡τ (∀`α τ) = cong ∀`α_ (trans (σ₁≡σ₂→σ₁τ≡σ₂τ τ extₛidₛ≡idₛ) (idₛτ≡τ τ))

⊢idₛ : ∀ {Γ : Ctx S} {t : Term S s} {T : Term S (kind-of s)} (⊢t : Γ ⊢ t ∶ T) → idₛ ∶ Γ ⇒ₛ Γ
⊢idₛ {Γ = Γ} ⊢t {eₛ} x = ⊢`x (sym (idₛτ≡τ (lookup Γ x)))
⊢idₛ {Γ = Γ} ⊢t {τₛ} x with lookup Γ x
... | ⋆ = ⊢τ

⊢singleₛ : ∀ {T' : Term S (kind-of s)} (⊢t : Γ ⊢ t ∶ T) → singleₛ idₛ t ∶ (Γ ▶ T') ⇒ₛ Γ
⊢singleₛ ⊢t {eₛ} x = {!   !} 
⊢singleₛ ⊢t {τₛ} x = {!   !}

-- Semantics ----------------------------------------------------------------------------

-- [latex] block(Val)

data Val : Expr S → Set where
  v-λ : Val (λ`x→ e)
  v-Λ : Val (Λ`α→ e)
  v-tt : ∀ {S} → Val (tt {S = S})

-- [latex] hide

infixr 3 _↪_
-- [latex] block(Semantics)
data _↪_ : Expr S → Expr S → Set where
  β-λ :
    Val e₂ →
    (λ`x→ e₁) · e₂ ↪ (e₁ [ e₂ ])
  β-Λ :
    (Λ`α→ e) • τ ↪ e [ τ ]
  β-let : 
    Val e₂ →
    let`x= e₂ `in e₁ ↪ (e₁ [ e₂ ])
  ξ-·₁ :
    e₁ ↪ e →
    ----------------
    e₁ · e₂ ↪ e · e₂
  ξ-·₂ :
    e₂ ↪ e →
    Val e₁ →
    e₁ · e₂ ↪ e₁ · e
  ξ-• :
    e ↪ e' →
    ----------------
    e • τ ↪ e' • τ
  ξ-let :
    e₂ ↪ e →
    let`x= e₂ `in e₁ ↪ let`x= e `in e₁ 

-- [latex] hide

-- Soundness ---------------------------------------------------------------------------- 

-- Progress

-- [latex] block(Progress)

progress : 
  ∅ ⊢ e ∶ τ →
  (∃[ e' ] (e ↪ e')) ⊎ Val e
progress ⊢⊤ = inj₂ v-tt
progress (⊢λ _) = inj₂ v-λ
progress (⊢Λ _) = inj₂ v-Λ
progress (⊢· {e₁ = e₁} {e₂ = e₂} ⊢e₁  ⊢e₂) with progress ⊢e₁ | progress ⊢e₂ 
... | inj₁ (e₁' , e₁↪e₁') | _ = inj₁ (e₁' · e₂ , ξ-·₁ e₁↪e₁')
... | inj₂ v | inj₁ (e₂' , e₂↪e₂') = inj₁ (e₁ · e₂' , ξ-·₂ e₂↪e₂' v)
... | inj₂ (v-λ {e = e₁}) | inj₂ v = inj₁ (e₁ [ e₂ ] , β-λ v)
progress (⊢• {τ = τ} ⊢e) with progress ⊢e 
... | inj₁ (e' , e↪e') = inj₁ (e' • τ , ξ-• e↪e')
... | inj₂ (v-Λ {e = e}) = inj₁ (e [ τ ] , β-Λ)
progress (⊢let  {e₂ = e₂} {e₁ = e₁} ⊢e₂ ⊢e₁) with progress ⊢e₂ 
... | inj₁ (e₂' , e₂↪e₂') = inj₁ ((let`x= e₂' `in e₁) , ξ-let e₂↪e₂')
... | inj₂ v = inj₁ (e₁ [ e₂ ] , β-let v)

-- [latex] hide

-- Subject Reduction

⊢ρ-preserves-Γ : ∀ {Γ₁ : Ctx S₁} {Γ₂ : Ctx S₂} (x : Var S₁ s) →
  ρ ∶ Γ₁ ⇒ᵣ Γ₂ →
  ren ρ (lookup Γ₁ x) ≡ lookup Γ₂ (ρ x)
⊢ρ-preserves-Γ x ⊢ρ = {!       !}

⊢ρ-preserves : ∀ {ρ : Ren S₁ S₂} {Γ₁ : Ctx S₁} {Γ₂ : Ctx S₂} {t : Term S₁ s} {T : Term S₁ (kind-of s)} →
  ρ ∶ Γ₁ ⇒ᵣ Γ₂ →
  Γ₁ ⊢ t ∶ T →
  Γ₂ ⊢ (ren ρ t) ∶ (ren ρ T)
⊢ρ-preserves ⊢ρ (⊢`x {x = x} refl) = ⊢`x (sym (⊢ρ-preserves-Γ x ⊢ρ))
⊢ρ-preserves ⊢ρ ⊢⊤ = ⊢⊤
⊢ρ-preserves ⊢ρ (⊢λ ⊢e) = {!   !} -- ⊢λ (subst (_ ⊢ _ ∶_) {!   !} (⊢• (⊢ρ-preserves (⊢extᵣ ⊢ρ) ⊢e)))
⊢ρ-preserves ⊢ρ (⊢Λ ⊢e) = ⊢Λ (⊢ρ-preserves (⊢extᵣ ⊢ρ) ⊢e)
⊢ρ-preserves ⊢ρ (⊢· ⊢e₁ ⊢e₂) = ⊢· (⊢ρ-preserves ⊢ρ ⊢e₁) (⊢ρ-preserves ⊢ρ ⊢e₂)
⊢ρ-preserves ⊢ρ (⊢• ⊢e) = {!   !} -- subst (_ ⊢ _ ∶_) {!   !} (⊢• (⊢ρ-preserves ⊢ρ ⊢e))
⊢ρ-preserves ⊢ρ (⊢let ⊢e₂ ⊢e₁) = ⊢let (⊢ρ-preserves ⊢ρ ⊢e₂) {!   !} 
⊢ρ-preserves ⊢ρ ⊢τ = ⊢τ

⊢wk-preserves : ∀ {Γ : Ctx S} {t : Term S s} {T : Term S (kind-of s)} {T' : Term S (kind-of s')} →
  Γ ⊢ t ∶ T →
  Γ ▶ T' ⊢ wk t ∶ wk T 
⊢wk-preserves ⊢e = ⊢ρ-preserves (⊢dropᵣ ⊢idᵣ) ⊢e

σ↑idₛ≡σ : ∀ (t : Term S₁ s) (t' : Term S₂ s') (σ : Sub S₁ S₂) →
  sub (singleₛ σ t') (wk t) ≡ sub σ t
σ↑idₛ≡σ t t' σ = {!   !}

⊢extₛ : ∀ {σ : Sub S₁ S₂} {Γ₁ : Ctx S₁} {Γ₂ : Ctx S₂} {t : Expr S₂} {τ : Type S₁} →
  σ ∶ Γ₁ ⇒ₛ Γ₂ →
  Γ₂ ⊢ t ∶ sub σ τ →
  singleₛ σ t ∶ Γ₁ ▶ τ ⇒ₛ Γ₂ 
⊢extₛ {σ = σ} {t = t} {τ = τ} ⊢σ ⊢e (here refl) = subst (_ ⊢ t ∶_) (sym (σ↑idₛ≡σ τ t σ)) ⊢e
⊢extₛ {σ = σ} {Γ₁ = Γ₁} {t = t} {τ = τ} ⊢σ ⊢e {eₛ} (there x) = subst (_ ⊢ σ x ∶_) (sym (σ↑idₛ≡σ (lookup Γ₁ x) t σ)) (⊢σ x)
⊢extₛ {σ = σ} {t = t} {τ = τ} ⊢σ ⊢e {τₛ} (there x) = {!   !}

τ[e]≡τ : ∀ {τ : Type S} {e : Expr S} → wk τ [ e ] ≡ τ  
τ[e]≡τ {τ = τ} {e = e} = 
  begin 
    wk τ [ e ]
  ≡⟨ {!  !} ⟩
    τ
  ∎

σ↑·wkt≡wk·σt : ∀ {s'} (σ : Sub S₁ S₂) (t : Term S₁ s) →
  sub (extₛ {s = s'} σ) (wk {s' = s'} t) ≡ wk (sub σ t)
σ↑·wkt≡wk·σt σ t = {!   !}

σ·t[t']≡σ↑·t[σ·t'] : ∀ {s'} (σ : Sub S₁ S₂) (t : Term (S₁ ▷ s') s) (t' : Term S₁ s') →
  sub σ (t [ t' ]) ≡ (sub (extₛ σ) t) [ sub σ t' ]  
σ·t[t']≡σ↑·t[σ·t'] = {!   !}

⊢σ↑ : ∀ {σ : Sub S₁ S₂} {Γ₁ : Ctx S₁} {Γ₂ : Ctx S₂} {T : Term S₁ (kind-of s)} →
  σ ∶ Γ₁ ⇒ₛ Γ₂ →
  extₛ σ ∶ Γ₁ ▶ T ⇒ₛ (Γ₂ ▶ sub σ T)
⊢σ↑ {σ = σ} {T = τ} ⊢σ {eₛ} (here refl) = ⊢`x (sym (σ↑·wkt≡wk·σt σ τ))
⊢σ↑ ⊢σ {τₛ} (here refl) = {!    !}
⊢σ↑ ⊢σ (there x) = {!   !}

-- [latex] block(preserves)
⊢σ-preserves : ∀ {σ : Sub S₁ S₂} {Γ₁ : Ctx S₁} {Γ₂ : Ctx S₂} {t : Term S₁ s} {T : Term S₁ (kind-of s)} →
  σ ∶ Γ₁ ⇒ₛ Γ₂ →
  Γ₁ ⊢ t ∶ T →
  Γ₂ ⊢ (sub σ t) ∶ (sub σ T)
-- [latex] hide
⊢σ-preserves ⊢σ (⊢`x {x = x} refl) = ⊢σ x
⊢σ-preserves ⊢σ ⊢⊤ = ⊢⊤
⊢σ-preserves {σ = σ} ⊢σ (⊢λ {τ' = τ'} ⊢e) = ⊢λ 
  (subst (_ ⊢ _ ∶_) (σ↑·wkt≡wk·σt σ τ') (⊢σ-preserves (⊢σ↑ ⊢σ) ⊢e))
⊢σ-preserves ⊢σ (⊢Λ ⊢e) = ⊢Λ (⊢σ-preserves (⊢σ↑ ⊢σ) ⊢e)
⊢σ-preserves ⊢σ (⊢· ⊢e₁ ⊢e₂) = ⊢· (⊢σ-preserves ⊢σ ⊢e₁) (⊢σ-preserves ⊢σ ⊢e₂)
⊢σ-preserves {σ = σ} ⊢σ (⊢• {e = e} {τ' = τ'} {τ = τ} ⊢e) =
  subst (_ ⊢ sub σ (e • τ) ∶_) (sym (σ·t[t']≡σ↑·t[σ·t'] σ τ' τ)) (⊢• (⊢σ-preserves ⊢σ ⊢e))
⊢σ-preserves {σ = σ} ⊢σ (⊢let {τ' = τ'} ⊢e₂ ⊢e₁) = ⊢let (⊢σ-preserves ⊢σ ⊢e₂) 
  (subst (_ ⊢ _ ∶_) (σ↑·wkt≡wk·σt σ τ') (⊢σ-preserves (⊢σ↑ ⊢σ) ⊢e₁))
  
⊢σ-preserves ⊢σ ⊢τ = ⊢τ

-- [latex] block(eepreserves)

e[e]-preserves :  ∀ {Γ : Ctx S} {e₁ : Expr (S ▷ eₛ)} {e₂ : Expr S} {τ τ' : Type S} →
  Γ ▶ τ ⊢ e₁ ∶ wk τ' →
  Γ ⊢ e₂ ∶ τ → 
  Γ ⊢ e₁ [ e₂ ] ∶ τ' 
-- [latex] hide
e[e]-preserves {τ = τ} ⊢e₁ ⊢e₂ = subst (_ ⊢ _ ∶_) τ[e]≡τ 
  (⊢σ-preserves (⊢extₛ (⊢idₛ ⊢e₂) (subst (_ ⊢ _ ∶_) (sym (idₛτ≡τ τ)) ⊢e₂)) ⊢e₁) 

-- [latex] block(etpreserves)

e[τ]-preserves :  ∀ {Γ : Ctx S} {e : Expr (S ▷ τₛ)} {τ : Type S} {τ' : Type (S ▷ τₛ)} →
  Γ ▶ ⋆ ⊢ e ∶ τ' →
  Γ ⊢ τ ∶ ⋆ →
  Γ ⊢ e [ τ ] ∶ τ' [ τ ] 
-- [latex] hide
e[τ]-preserves ⊢e ⊢τ = ⊢σ-preserves (⊢singleₛ ⊢τ) ⊢e

-- [latex] block(SubjectReduction)

subject-reduction : ∀ {Γ : Ctx S} →
  Γ ⊢ e ∶ τ →
  e ↪ e' →
  Γ ⊢ e' ∶ τ
subject-reduction (⊢· (⊢λ ⊢e₁) ⊢e₂) (β-λ v₂) = e[e]-preserves ⊢e₁ ⊢e₂
subject-reduction (⊢· ⊢e₁ ⊢e₂) (ξ-·₁ e₁↪e) = ⊢· (subject-reduction ⊢e₁ e₁↪e) ⊢e₂
subject-reduction (⊢· ⊢e₁ ⊢e₂) (ξ-·₂ e₂↪e x) = ⊢· ⊢e₁ (subject-reduction ⊢e₂ e₂↪e)
subject-reduction (⊢• (⊢Λ ⊢e)) β-Λ = e[τ]-preserves ⊢e ⊢τ
subject-reduction (⊢• ⊢e) (ξ-• e↪e') = ⊢• (subject-reduction ⊢e e↪e')
subject-reduction (⊢let ⊢e₂ ⊢e₁) (β-let v₂) = e[e]-preserves ⊢e₁ ⊢e₂
subject-reduction (⊢let ⊢e₂ ⊢e₁) (ξ-let e₂↪e') = ⊢let (subject-reduction ⊢e₂ e₂↪e') ⊢e₁  

-- [latex] end    