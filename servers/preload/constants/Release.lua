local Release = {
	STATUS_FAILED  = 1;--
	STATUS_VOTING  = 2;--
	STATUS_SUCCESS = 3;

	VOTE_REFUS     = 11;
	VOTE_NO_OP     = 12;
	VOTE_AGREE     = 13;

	APPLY_EXIT    = 100;
	APPLY_RELEASE = 101;	
	APPLY_VOTE    = 102;

	RELEASE_NORMAL     =  201;--正常结束
	RELEASE_CREATOR    =  202;
	RELEASE_VOTE       =  203;
}
return Release