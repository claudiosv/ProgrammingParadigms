%Claudio Spiess 14329
-module(counter).
-export([word_count/2,word_count/0]).

count(Words) -> %Count words function
receive
    eof -> %eof message, prints to standard output all received words together with their occurrences.
        %io:format("EOF reached~n"), DEBUG CODE
        Keys = maps:keys(Words), %get all the keys of the Words map
        %Function that prints the Words map
        Printer = fun(Key) -> io:format("~p: ~p occurences~n", [Key, maps:get(Key,Words)]) end, %get the occurences per key
        lists:foreach(Printer, Keys); %call the function for each key
    Word -> %if variable is received instead of eof atom
        if
            is_map(Words) -> %sanity check, ensure Words is a map
                Increment = fun(Count) -> Count + 1 end, %incrementer function, increase value by +1
                NewWords = maps:update_with(Word,Increment,1,Words); %update word occurence count, if word doesn't exist, use default value 1
            true -> %fallback
                NewWords = #{ Word => 1 } %make a new map with count 1 for received word
        end,
        count(NewWords) %loop!
end.

scanner() -> %scanner before a pid is received
receive
    {pid,CounterPid} -> %get counter CounterPid
        %io:format("Received counter CounterPid~n"),
        scanner(CounterPid) %call the real scanner with counter pid
end.

scanner(CounterPid) ->
receive
    {message,eof,Reader} -> %message when reader informs scanner of EOF
        %io:format("Received EOF~n"),
        Reader ! eof; %message the reader back, this can only be reached if the function below has finished executing
    {message,Message} -> %get message (line)
        %io:format("Received message: ~p~n", [Message]), DEBUG CODE
        %  scanner splits the line into words, and sends each word to the counter.
        Words = string:tokens(Message, " "), %split into tokens
        %io:format("Debug: ~p~n", [CounterPid]), DEBUG CODE
        SendToCounter = fun(Word) -> CounterPid ! Word end, %word sender function
        lists:foreach(SendToCounter, Words), %send all words to counter
        scanner(CounterPid) %loop!
end.

word_count() -> %debug function with sample input
    FileName = "input.txt",
    N = 4,
    word_count(FileName, N).
word_count(FileName,N) ->
    reader(FileName, N). %start reader

reader(FileName,N) ->
    Counter = spawn(fun () -> count(#{}) end), %spawn a counter with empty map
    Scanners = spawn_scanner(N,spawn_scanner()), %call scanner spawner
    SendPidToScanner = fun(Scanner) -> Scanner ! {pid,Counter} end, %function to send counter pid to scanner
    lists:foreach(SendPidToScanner, Scanners), %send counter pid to all scanners
    {ok, Device} = file:open(FileName, [read]), %open the file, with help from https://stackoverflow.com/a/2475613
    Accumulator = 1, %make an accumulator variable
    try 
        dispatch_lines(Scanners, Accumulator, N, Device) %call recursive function to read line by line and send to scanner in round robin fashion until done
      after
        SendEofScanner = fun(Scanner) -> Scanner ! {message,eof,self()} end, %send eof message to scanner
        lists:foreach(SendEofScanner, Scanners) %send to all scanners
    end,
    %io:format("Scanners completed~n"), DEBUG CODE
    wait_for_scanners(1, N), %initialize accumulator/counter to 1, wait for scanners to finish (N number of scanners)
    Counter ! eof, %send eof message to counter
    file:close(Device). %close file handle

wait_for_scanners(FinishedScannerCount, N) -> %recursive function to wait for all scanners to send finished messages
receive
    eof when FinishedScannerCount==N -> %if the number of scanners who have sent the finished message matches the number of scanners, return ok
       % io:format("Waiter received EOF, all done!!~n"), DEBUG CODE
        ok;
    eof when FinishedScannerCount<N -> %if the number of finished scanners is less than the number of scanners, keep waiting
           % io:format("Waiter received EOF, not all done~n"),
        NewFinishedScannerCount = FinishedScannerCount + 1, %increment number of finished scanners
        wait_for_scanners(NewFinishedScannerCount, N) %recursion
end.

dispatch_lines(Scanners, Accumulator, NumScanners, Device) -> %function to send each line to a scanner
    case io:get_line(Device, "") of %get line
        eof  -> []; %if eof is reached, return nil
        Line -> %if a variable is received, it must be a line, process it
            %find scanner to send to
            if
                Accumulator<NumScanners -> %if accumulator is less than number of scanners, set scanner to Nth scanner
                    Scanner = lists:nth(Accumulator,Scanners), %set scanner to Nth scanner
                    NewAccumulator = Accumulator+1; %set accumulator to N+1 for recursive call
                Accumulator==NumScanners -> %if accumulator reaches number of scanners, loop back to 1
                    Scanner = lists:nth(Accumulator,Scanners),
                    NewAccumulator = 1
            end,
            Scanner ! {message, string:trim(Line)}, %send message to scanner containing trimmed line of text
            dispatch_lines(Scanners, NewAccumulator, NumScanners, Device) %recursive call to keep sending lines
    end.

spawn_scanner() -> %simple call to spawn a new scanner process
    spawn(fun () -> scanner() end).

spawn_scanner(0,_) -> %pattern matching for when counter has reached 0, help from https://www.tutorialspoint.com/erlang/erlang_loops.htm
   []; %return empty list

spawn_scanner(N,Term) when N > 0 -> %pattern matching for when there are scanners left to spawn
  % io:fwrite("Spawned scanner~n"), DEBUG CODE
   [Term|spawn_scanner(N-1,spawn_scanner())]. %append new scanner to list, decrement accumulator in recursive call