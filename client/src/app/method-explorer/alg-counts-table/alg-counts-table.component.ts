import { Component, Input } from '@angular/core';
import { ExecutionOrder, MethodDescription } from '../../utils/cube-stats/method-description';
import { MethodExplorerService } from '../method-explorer.service';
import { AlgCountsRow } from '../alg-counts-data.model';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

class RenderableAlgCountsRow {
  constructor(readonly row: AlgCountsRow) {}

  get pluralName() {
    return this.row.pluralName;
  }

  get threeCycles() {
    return this.row.algCounts.cyclesByLength[3].toFixed(2);
  }

  get fiveCycles() {
    return this.row.algCounts.cyclesByLength[5].toFixed(2);
  }

  get doubleSwaps() {
    return this.row.algCounts.doubleSwaps.toFixed(2);
  }
  
  get twoTwists() {
    return this.row.algCounts.twistsByNumUnoriented[2].toFixed(2);
  }
  
  get threeTwists() {
    return this.row.algCounts.twistsByNumUnoriented[3].toFixed(2);
  }
  
  get fourTwists() {
    return this.row.algCounts.twistsByNumUnoriented[4].toFixed(2);
  }
  
  get totalTwists() {
    return this.row.algCounts.totalTwists.toFixed(2);
  }
  
  get total() {
    return this.row.algCounts.total.toFixed(2);
  }
}

@Component({
  selector: 'cube-trainer-alg-counts-table',
  templateUrl: './alg-counts-table.component.html',
  styleUrls: ['./alg-counts-table.component.css']
})
export class AlgCountsTableComponent {
  @Input() readonly expectedAlgsData;

  get expectedAlgsRows(): RenderableAlgCountsRow[] {
    return expectedAlgsData.rows.map(row => new RenderableExpectedAlgRow(row));
  }

  readonly columnsToDisplay = ['name', 'threeCycles', 'fiveCycles', 'doubleSwaps', 'parities', 'parityTwists', 'total'];
}
