import { RailsService } from '../rails/rails.service';
import { CableService } from '../rails/cable.service';
import { Injectable } from '@angular/core';
import { HttpVerb } from '../rails/http-verb';
import { Message } from './message.model';
import { MessageNotification } from './message-notification.model';
import { map } from 'rxjs/operators';
import { fromDateString } from '../utils/instant'
import { Observable } from 'rxjs';

function parseMessage(message: any): Message {
  return {
    id: message.id,
    title: message.title,
    body: message.body,
    read: message.read,
    timestamp: fromDateString(message.created_at),
  }
}

interface UnreadMessagesCount {
  readonly unread_messages_count: number;
}

@Injectable({
  providedIn: 'root',
})
export class MessagesService {
  constructor(private readonly rails: RailsService,
              private readonly cableService: CableService) {}

  markAsRead(messageId: number): Observable<void> {
    return this.rails.ajax<void>(HttpVerb.Put, `/messages/${messageId}`, {message: {read: true}})
  }

  destroy(messageId: number): Observable<void> {
    return this.rails.ajax<void>(HttpVerb.Delete, `/messages/${messageId}`, {})
  }

  list(): Observable<Message[]> {
    return this.rails.ajax<any[]>(HttpVerb.Get, '/messages', {}).pipe(
      map(messages => messages.map(parseMessage)));
  }

  show(messageId: number): Observable<Message> {
    return this.rails.ajax<any>(HttpVerb.Get, `/messages/${messageId}`, {}).pipe(
      map(parseMessage));
  }

  unreadCountNotifications(): Observable<number> {
    return this.cableService.channelSubscription<UnreadMessagesCount>('UnreadMessagesCountChannel').pipe(map(m => m.unread_messages_count));
  }

  notifications(): Observable<MessageNotification> {
    return this.cableService.channelSubscription<MessageNotification>('MessageChannel');
  }
}
