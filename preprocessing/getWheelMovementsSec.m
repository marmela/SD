function wheelMovementsSec = getWheelMovementsSec(wheelEventsTimeSec)

N_EVENTS_TO_CHECK_SPEED = 4;
MAX_TIME_BETWEEN_EVENETS_SEC = 2;
PRE_PADDING_SEC = 0.5;
POST_PADDING_SEC = 0.5;
wheelEventsTimeSec = makeColumn(wheelEventsTimeSec);
wheelEventsTimeSec = [-Inf; wheelEventsTimeSec; Inf];
wheelTimeDiff = wheelEventsTimeSec(1+N_EVENTS_TO_CHECK_SPEED:end)-...
    wheelEventsTimeSec(1:end-N_EVENTS_TO_CHECK_SPEED);
isWheelMoving = wheelTimeDiff<MAX_TIME_BETWEEN_EVENETS_SEC;
isMoveOnset = diff(isWheelMoving)>0;
isMoveOffset = diff(isWheelMoving)<0;
onset = wheelEventsTimeSec(find(isMoveOnset)+1);
offset = wheelEventsTimeSec(find(isMoveOffset)+N_EVENTS_TO_CHECK_SPEED);
assert(length(onset) == length(offset));
assert(all(onset<offset));
onset = onset-PRE_PADDING_SEC;
offset = offset+POST_PADDING_SEC;
wheelMovementsSec = table(onset,offset);
end