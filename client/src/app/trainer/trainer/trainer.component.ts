import { Case } from '../case.model';
import { Component } from '@angular/core';
import { map, switchMap } from 'rxjs/operators';
import { Mode } from '../../modes/mode.model';
import { ModesService } from '../../modes/modes.service';
import { ActivatedRoute } from '@angular/router';
import { Observable, Subject } from 'rxjs';

@Component({
  selector: 'cube-trainer-trainer',
  templateUrl: './trainer.component.html'
})
export class TrainerComponent {
  casee: Case | undefined = undefined;
  numHints = 0;
  mode$: Observable<Mode>
  resultEventsSubject = new Subject<void>();

  constructor(private readonly modesService: ModesService,
	      activatedRoute: ActivatedRoute) {
    this.mode$ = activatedRoute.params.pipe(
      map(p => p['modeId']),
      switchMap(modeId => this.modesService.show(modeId)),
    );
  }

  onResultsModified() {
    this.resultEventsSubject.next();
  }

  onCase(casee: Case) {
    this.casee = casee;
  }

  onNumHints(numHints: number) {
    this.numHints = numHints;
  }
}
