import { Component, Input } from '@angular/core';
import { Mode } from '../modes/mode';
import { ShowInputMode } from '../modes/show-input-mode';
import { TrainerService } from './trainer.service';
import { InputItem } from './input-item';
import { ImgSide } from './img-side';

@Component({
  selector: 'cube-trainer-trainer-input',
  templateUrl: './trainer-input.component.html',
  styles: [`
.trainer-input {
  font-size: xxx-large;
}
`]
})
export class TrainerInputComponent {
  @Input()
  input!: InputItem;

  @Input()
  mode!: Mode

  @Input()
  numHints!: number;

  constructor(private readonly trainerService: TrainerService) {}

  get hints() {
    return this.input?.hints ? this.input.hints : [];
  }

  get showImage() {
    return this.mode && this.mode.showInputMode == ShowInputMode.Picture;
  }

  get showName() {
    return this.mode && this.mode.showInputMode == ShowInputMode.Name;
  }

  get imgLeftSrc() {
    return this.imgSrc(ImgSide.Left);
  }

  get imgRightSrc() {
    return this.imgSrc(ImgSide.Right);
  }

  imgSrc(imgSide: ImgSide) {
    return this.mode && this.input && this.showImage ? this.trainerService.inputImgSrc(this.mode, this.input, imgSide) : undefined;
  }
}
