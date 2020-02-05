Require Import Coq.ZArith.ZArith.
Require Import coqutil.Z.Lia.
Require Import coqutil.Word.Interface coqutil.Datatypes.HList coqutil.Datatypes.PrimitivePair.
Require Import coqutil.Word.Properties.
Require Import coqutil.Z.bitblast.
Require Import coqutil.Byte.
Local Set Universe Polymorphism.

Local Open Scope Z_scope.

Section LittleEndian.

  Fixpoint combine (n : nat) : forall (bs : tuple byte n), Z :=
    match n with
    | O => fun _ => 0
    | S n => fun bs => Z.lor (byte.unsigned (pair._1 bs))
                             (Z.shiftl (combine n (pair._2 bs)) 8)
    end.

  Fixpoint split (n : nat) (w : Z) : tuple byte n :=
    match n with
    | O => tt
    | S n => pair.mk (byte.of_Z w) (split n (Z.shiftr w 8))
    end.

  Lemma combine_split (n : nat) (z : Z) :
    combine n (split n z) = z mod 2 ^ (Z.of_nat n * 8).
  Proof.
    revert z; induction n.
    - cbn. intros. rewrite Z.mod_1_r. trivial.
    - cbn [split combine PrimitivePair.pair._1 PrimitivePair.pair._2]; intros.
      erewrite IHn; clear IHn.
      rewrite byte.unsigned_of_Z, Nat2Z.inj_succ, Z.mul_succ_l by blia.
      unfold byte.wrap.
      rewrite <-! Z.land_ones by blia.
      Z.bitblast.
  Qed.

  Lemma split_combine (n: nat) bs :
    split n (combine n bs) = bs.
  Proof.
    revert bs; induction n.
    - destruct bs. reflexivity.
    - destruct bs; cbn [split combine PrimitivePair.pair._1 PrimitivePair.pair._2]; intros.
      specialize (IHn _2).
      f_equal.
      { eapply byte.unsigned_inj.
        rewrite byte.unsigned_of_Z, <-byte.wrap_unsigned; cbv [byte.wrap].
        Z.bitblast; cbn; subst.
        rewrite (Z.testbit_neg_r _ (i-8)) by bomega.
        Z.bitblast_core. }
      { rewrite <-IHn.
        rewrite combine_split.
        f_equal.
        rewrite <-byte.wrap_unsigned; cbv [byte.wrap].
        Z.bitblast; subst; cbn.
        rewrite <-IHn.
        rewrite combine_split.
        Z.bitblast_core. }
  Qed.

End LittleEndian.

Arguments combine: simpl never.
Arguments split: simpl never.
