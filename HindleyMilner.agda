open import Common using (_▷_; _▷▷_)
open import Data.List using (List; []; _∷_; drop; _++_)
open import Data.List.Membership.Propositional using (_∈_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Data.Sum.Base using (_⊎_; inj₁; inj₂)
open import Data.Nat using (ℕ; zero; suc)
open import Data.List.Relation.Unary.Any using (here; there)
open import Function using (id; _∘_)
open import Data.Unit using (⊤; tt)
open import Data.Empty using (⊥)
open import Data.Product using (_×_; _,_; Σ-syntax; ∃-syntax)
open import Data.List.Relation.Unary.Any using (Any)
open import Relation.Nullary using (¬_)

module HindleyMilner where

-- Sorts --------------------------------------------------------------------------------

data Ctxable : Set where
  ⊤ᶜ : Ctxable
  ⊥ᶜ : Ctxable

data Sort : Ctxable → Set where
  eₛ  : Sort ⊤ᶜ
  vₛ  : Sort ⊥ᶜ
  σₛ  : Sort ⊤ᶜ
  τₛ  : Sort ⊤ᶜ

Sorts : Set
Sorts = List (Sort ⊤ᶜ)

variable
  r r' r'' r₁ r₂ : Ctxable
  s s' s'' s₁ s₂ : Sort r
  S S' S'' S₁ S₂ : Sorts
  x x' x'' x₁ x₂ : eₛ ∈ S
  α α' α'' α₁ α₂ : τₛ ∈ S

Var : Sorts → Sort ⊤ᶜ → Set
Var S s = s ∈ S

-- Syntax -------------------------------------------------------------------------------

infixr 4 λ`x→_ `let`x=_`in_ ∀`α_
infixr 5 _⇒_ _·_
infix  6 `_ ↑ₚ_

data Term : Sorts → Sort r → Set where
  `_           : Var S s → Term S s
  tt           : Term S eₛ
  λ`x→_        : Term (S ▷ eₛ) eₛ → Term S eₛ
  _·_          : Term S eₛ → Term S eₛ → Term S eₛ
  `let`x=_`in_ : Term S eₛ → Term (S ▷ eₛ) eₛ → Term S eₛ
  val-λ`x→_    : Term (S ▷ eₛ) eₛ → Term S vₛ
  val-tt       : Term S vₛ
  `⊤           : Term S τₛ
  _⇒_          : Term S τₛ → Term S τₛ → Term S τₛ
  ∀`α_         : Term (S ▷ τₛ) σₛ → Term S σₛ
  ↑ₚ_          : Term S τₛ → Term S σₛ

Expr : Sorts → Set
Expr S = Term S eₛ
Poly : Sorts → Set
Poly S = Term S σₛ
Mono : Sorts → Set
Mono S = Term S τₛ
Val : Sorts → Set
Val S = Term S vₛ

variable
  e e' e'' e₁ e₂ : Expr S
  v v' v'' v₁ v₂ : Val S
  σ σ' σ'' σ₁ σ₂ : Poly S
  τ τ' τ'' τ₁ τ₂ : Mono S

⌞_⌟ : Val S → Expr S
⌞ val-λ`x→ e ⌟ = λ`x→ e
⌞ val-tt ⌟ = tt

-- Context ------------------------------------------------------------------------------

Stores : Sorts → Sort ⊤ᶜ → Set
Stores S eₛ = Poly S
Stores S τₛ = ⊤
Stores S σₛ = ⊤

depth : Var S s → ℕ
depth (here px) = zero
depth (there x) = suc (depth x)

drop-last : ∀ {S s} → Var S s → Sorts → Sorts
drop-last = drop ∘ suc ∘ depth

Ctx : Sorts → Set
Ctx S = ∀ {s} → (v : Var S s) → Stores (drop-last v S) s

infix 30 _▶_
_▶_ : Ctx S → Stores S s → Ctx (S ▷ s)
(Γ ▶ γ) (here refl) = γ
(Γ ▶ _) (there x) = Γ x

wk-τ : Mono S → Mono (S ▷ s')
wk-τ `⊤ = `⊤
wk-τ (` x) = ` there x
wk-τ (τ₁ ⇒ τ₂) = (wk-τ τ₁ ⇒ wk-τ τ₂) 

postulate   
  wk-e : Expr S → Expr (S ▷ s')
  wk-σ : Poly S → Poly (S ▷ s')
  {- wk-σ (` x) = ` there x
  wk-σ (∀`α σ) = ∀`α {!   !}
  wk-σ (↑ₚ τ) = ↑ₚ (wk-τ τ) -}

wkₛ : Stores S s → Stores (S ▷ s') s
wkₛ {s = eₛ} σ = wk-σ σ
wkₛ {s = σₛ} _ = tt
wkₛ {s = τₛ} _ = tt  

wk-dropped : (v : Var S s) → Stores (drop-last v S) s → Stores S s
wk-dropped (here refl) t = wkₛ t
wk-dropped (there x) t = wkₛ (wk-dropped x t)

wk-ctx : Ctx S → Var S s → Stores S s 
wk-ctx Γ x = wk-dropped x (Γ x)

variable 
  Γ Γ' Γ'' Γ₁ Γ₂ : Ctx S
  ∅ : Ctx []

-- Renaming -----------------------------------------------------------------------------

Ren : Sorts → Sorts → Set
Ren S₁ S₂ = ∀ {s} → Var S₁ s → Var S₂ s

extᵣ : Ren S₁ S₂ → Ren (S₁ ▷ s) (S₂ ▷ s)
extᵣ ρ (here refl) = here refl
extᵣ ρ (there x) = there (ρ x)

ren : Ren S₁ S₂ → (Term S₁ s → Term S₂ s)
ren ρ (` x) = ` (ρ x)
ren ρ tt = tt
ren ρ (λ`x→ e) = λ`x→ (ren (extᵣ ρ) e)
ren ρ (e₁ · e₂) = (ren ρ e₁) · (ren ρ e₂)
ren ρ (`let`x= e₂ `in e₁) = `let`x= (ren ρ e₂) `in ren (extᵣ ρ) e₁
ren ρ (val-λ`x→ e) = val-λ`x→ (ren (extᵣ ρ) e) 
ren ρ val-tt = val-tt
ren ρ `⊤ = `⊤
ren ρ (τ₁ ⇒ τ₂) = ren ρ τ₁ ⇒ ren ρ τ₂
ren ρ (↑ₚ τ) = ↑ₚ ren ρ τ
ren ρ (∀`α σ) = ∀`α (ren (extᵣ ρ) σ)
wkᵣ : Ren S (S ▷ s) 
wkᵣ = there

-- Substitution -------------------------------------------------------------------------

binds : Sort r → Sort ⊤ᶜ 
binds eₛ = eₛ
binds σₛ = τₛ
binds τₛ = τₛ
binds vₛ = eₛ

Sub : Sorts → Sorts → Set
Sub S₁ S₂ = ∀ {s} → Var S₁ s → Term S₂ s

extₛ : Sub S₁ S₂ → Sub (S₁ ▷ s) (S₂ ▷ s)
extₛ ξ (here refl) = ` here refl
extₛ ξ (there x) = ren wkᵣ (ξ x)

sub : Sub S₁ S₂ → (Term S₁ s → Term S₂ s)
sub ξ (` x) = (ξ x)
sub ξ tt = tt
sub ξ (λ`x→ e) = λ`x→ (sub (extₛ ξ) e)
sub ξ (e₁ · e₂) = sub ξ e₁ · sub ξ e₂
sub ξ (`let`x= e₂ `in e₁) = `let`x= sub ξ e₂ `in (sub (extₛ ξ) e₁)
sub ξ (val-λ`x→ e) = val-λ`x→ (sub (extₛ ξ) e)
sub ξ val-tt = val-tt 
sub ξ `⊤ = `⊤
sub ξ (τ₁ ⇒ τ₂) = sub ξ τ₁ ⇒ sub ξ τ₂
sub ξ (∀`α σ) = ∀`α (sub (extₛ ξ) σ)
sub ξ (↑ₚ τ) = ↑ₚ sub ξ τ

intro :  Term S (binds s) → Sub (S ▷ (binds s)) S
intro e (here refl) = e
intro e (there x) = ` x 

_[_] : Term (S ▷ (binds s)) s → Term S (binds s) → Term S s
e₁ [ e₂ ] = sub (intro e₂) e₁

variable
  ξ ξ' ξ'' ξ₁ ξ₂ : Sub S S₂ 

-- Typing -------------------------------------------------------------------------------

infixr 3 _⊢_∶_
data _⊢_∶_ : Ctx S → Expr S → Poly S → Set where
  ⊢-`x :  
    wk-ctx Γ x ≡ σ →
    ----------------
    Γ ⊢ ` x ∶ σ
  ⊢-⊤ : 
    --------------
    Γ ⊢ tt ∶ ↑ₚ `⊤
  ⊢-λ : 
    Γ ▶ (↑ₚ τ₁) ⊢ e ∶ ↑ₚ (wk-τ τ₂) →  
    ---------------------------
    Γ ⊢ λ`x→ e ∶ ↑ₚ (τ₁ ⇒ τ₂)
  ⊢-· : 
    Γ ⊢ e₁ ∶ ↑ₚ (τ₁ ⇒ τ₂) →
    Γ ⊢ e₂ ∶ ↑ₚ τ₁ →
    -----------------------
    Γ ⊢ e₁ · e₂ ∶ ↑ₚ τ₂
  ⊢-let : 
    Γ ⊢ e₂ ∶ σ →
    Γ ▶ σ ⊢ e₁ ∶ ↑ₚ (wk-τ τ) →
    ----------------------------
    Γ ⊢ `let`x= e₂ `in e₁ ∶ ↑ₚ τ
  ⊢-τ : 
    Γ ⊢ e ∶ ∀`α σ →
    --------------------
    Γ ⊢ e ∶ (σ [ τ ])
  ⊢-∀ : 
    Γ ⊢ e ∶ σ → 
    ------------------
    Γ ⊢ e ∶ ∀`α wk-σ σ 

-- Semantics ----------------------------------------------------------------------------

{- infixr 3 _↓_
data _↓_ : Expr S → Val S → Set where
  ↓-tt :
    -----------
    tt ↓ val-tt
  ↓-λ :
    -------------------
    λ`x→ e ↓ val-λ`x→ e
  ↓-· : 
    e₁ ↓ val-λ`x→ e →
    e₂ ↓ v' → 
    e [ ⌞ v' ⌟ ] ↓ v →
    -----------------
    e₁ · e₂ ↓ v
  ↓-let :
    e₂ ↓ v' → 
    e₁ [ ⌞ v' ⌟ ] ↓ v →
    ---------------
    `let`x= e₂ `in e₁ ↓ v  -}

-- Soundness -----------------------------------------------------------------------------

{- subst-preserve : 
  Γ ⊢ e' ∶ σ' →
  Γ ▶ τ' ⊢ e ∶ wk-σ σ →
  ---------------------
  Γ ⊢ e [ e' ] ∶ σ
subst-preserve a b = {!   !}

inv : 
  Γ ⊢ λ`x→ e ∶ ↑ₚ (τ₁ ⇒ τ₂) → 
  -------------------------
  Γ ▶ τ₁ ⊢ e ∶ ↑ₚ (wk-τ τ₂)
inv a = {!   !}

soundness : 
  ∅ ⊢ e ∶ σ →
  e ↓ v' →
  ∅ ⊢ ⌞ v' ⌟ ∶ σ
soundness (⊢-λ ⊢e) ↓-λ = ⊢-λ ⊢e
soundness ⊢-⊤ r = {!   !}
soundness (⊢-· ⊢e₁ ⊢e₂) (↓-· e₁↓λ`x→e e₂↓v' e[v']↓v) with inv (soundness ⊢e₁ e₁↓λ`x→e)
... | ⊢e' = soundness (subst-preserve (soundness ⊢e₂ e₂↓v') ⊢e') e[v']↓v
soundness (⊢-let ⊢e₂ ⊢e₁) (↓-let e₂↓v' e₁[v']↓v) with soundness ⊢e₂ e₂↓v'
... | ⊢e₂' = soundness (subst-preserve ⊢e₂' ⊢e₁) e₁[v']↓v
soundness (⊢-τ ⊢e) e↓v  = ⊢-τ (soundness ⊢e e↓v)
soundness (⊢-∀ ⊢e) e↓v = ⊢-∀ (soundness ⊢e e↓v)   -}