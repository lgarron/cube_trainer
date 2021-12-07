import { PiecePermutationDescription } from './piece-permutation-description';
import { sum } from '../utils';
import { Piece } from './piece';
import { assert } from '../assert';
import { ncr, factorial } from './combinatorics-utils';

// Represents one big group of similar scrambles, i.e.
// * same number of pieces solved
// * same number of pieces twisted or flipped
// * same number of pieces permuted
// * same cycle sizes.
export class BigScrambleGroup {
  constructor(
    readonly description: PiecePermutationDescription,
    // Solved pieces.
    readonly solved: Piece[],
    // Only used for corners, edges and midges.
    // It's an array because there can be multiple types of unoriented.
    // (clockwise and counter-clockwise for corners)
    readonly unorientedByType: Piece[][],
    // Permuted pieces
    readonly permuted: Piece[],
    readonly sortedCycleLengths: number[]) {
    assert(description.pieces.length === this.solved.length + sum(this.unorientedByType.map(e => e.length)) + this.permuted.length, `inconsistent number of pieces (${description.pieces.length} vs ${this.solved.length} + ${sum(this.unorientedByType.map(e => e.length))} + ${this.permuted.length})`);
    assert(sum(sortedCycleLengths) ===  this.permuted.length, 'inconsistent number of pieces and cycle lengths');
  }

  get unorientedTypes() {
    return this.unorientedByType.length;
  }

  get pieces() {
    return this.description.pieces;
  }

  // Number of permutations in this group.
  get count() {
    let remainingPieces = this.permuted.length;
    let permutedChoices = 1;
    let lastCycleLength = 0;
    let numCyclesWithLastLength = 0;
    // We have to divide by this to account for the fact that we don't
    // care about the order in case of multiple cycles of the same length.
    let cyclePermutationDivisor = 1;
    // For all except for the last permuted piece, we can choose the orientation.
    // Note that in case of no permuted pieces, we took care of excluding invalid
    // possibilities earlier.
    const permutationOrientationChoices = this.permuted.length > 0 ? (this.unorientedTypes + 1) ** (this.permuted.length - 1) : 1;
    this.sortedCycleLengths.forEach(cycleLength => {
      // Choices for the pieces in this cycle plus orders within the cycle.
      permutedChoices *= ncr(remainingPieces, cycleLength) * factorial(cycleLength - 1);
      remainingPieces -= cycleLength;
      if (cycleLength === lastCycleLength) {
        ++numCyclesWithLastLength;
      } else {
        cyclePermutationDivisor *= factorial(numCyclesWithLastLength); 
        lastCycleLength = cycleLength;
        numCyclesWithLastLength = 1;
      }
    });
    cyclePermutationDivisor *= factorial(numCyclesWithLastLength);
    assert(this.unorientedTypes <= 2);
    // If there are 2 orientation types (i.e for corners)
    // and there is a different number of unoriented pieces for the two unoriented types,
    // we have to multiply by 2 for those two choices.
    const unorientedTypeChoices = this.unorientedTypes === 2 && this.unorientedByType[0].length + this.unorientedByType[1].length > 0 ? 2 : 1;
    return permutedChoices * unorientedTypeChoices * permutationOrientationChoices / cyclePermutationDivisor;
  }
}
