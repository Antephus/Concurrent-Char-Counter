%% Carrie Morris
-module (concurrentCount).
-export ([load/1, count/3, countSplit/2, join/2, split/2, printBinList/1]).

%%% Concurrent Character Count %%%
load(Filename)
->
	{ok, Bin} = file:read_file(Filename),
	List = binary_to_list(Bin),
	Length = round(length(List)/20),
	LowList = string:to_lower(List),
	
	SplitList = split(LowList, Length),
	io:fwrite("Loaded and Split~n"),
	Result = countChars(SplitList, []),
	Result.

join(PID, AccumCount)
->
	io:fwrite("Join Spawned~n"),
	receive
	{From, {split, Result}}
		->
			SplitCount = Result,
			join(PID, SplitCount, AccumCount);
	_Other -> {error, unknown}
	end.
	
join(PID, [], Result)
-> 
	PID ! {self(), {accumulated, Result}},
	io:fwrite("Joined~n");
join(PID, Split, [])
-> 
	%%% Called innappropriately too often due to weird results from count funcs below...
	PID ! {self(), {accumulated, Split}},
	io:fwrite("First split sent~n");
join(PID, [SplitH|SplitT], [AccumH|AccumT])
->
	{_Char1, Count1} = SplitH,
	{Char2, Count2} = AccumH,
	[{Char2, Count1 + Count2}] ++ join(PID, SplitT, AccumT).
 
countChars([], Result)
-> Result;
countChars([Split|RestofList], Result)
->
	JoinPID = spawn(assignment, join, [self(), Result]),
	_CountPID = spawn(assignment, countSplit, [JoinPID, Split]),
	AccumResult = receive
	{From, {accumulated, Accum}}
		->
			Accum;
	_Other -> {error, unknown}
	end,
	countChars(RestofList, AccumResult).

printBinList([])
-> io:fwrite("[]~n");	
printBinList([H|T])
->
	io:fwrite("~w~n", [H]),
	printBinList(T).
	
countSplit(PID, Split)
->
	io:fwrite("Count spawned~n"),
	Alph = [$a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n, $o, $p, $q, $r, $s, $t, $u, $v, $w, $x, $y, $z],
	countSplit(PID, Alph, Split, []).


	
countSplit(PID, [], _Split, Result)
->
	PID ! {self(), {split, Result}};
	%%% Crazy, totally random, wtf lists of chars produced here -
	%%% random amounts of random chars seems like?? Un comment to see
	% printBinList(Result),
	%io:fwrite("~n");
countSplit(PID, [CurrentChar|RestofChars], Split, PriorResults)
->
	Count = count(CurrentChar, Split, 0),
	Result = PriorResults ++ [{CurrentChar, Count}],
	countSplit(PID, RestofChars, Split, Result).

split([], _)
-> [];
split(List, SplitLength)
->
	%% Get a split of the list
	Split = string:substr(List, 1, SplitLength),
	
	%% Check if the list is longer than the split 
	case length(List) > SplitLength of
		true -> RestofList = string:substr(List, SplitLength + 1, length(List));
		false -> RestofList = []
	end,
	[Split] ++ split(RestofList, SplitLength).

count(_Char, [], Count)
-> Count;
count(Char, [H|T], Count)
->
	case Char == H of
		true -> count(Char, T, Count + 1);
		false -> count(Char, T, Count)
	end.