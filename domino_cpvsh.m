%Game of dominoes, 1 computer against 1 human
clear;
clc;
game=1;
[d, p]=initTiles(); %list of dominoes and pairs CONSTANTS
table=0;
fringe=[-1,-1]; %both ends of the table
[h1, h2, deck]=distrib(); %distribution of the dominoes
order=[ones(28,1) 2*ones(28,1)];
%evenTurn=1;
playerTurn=playOrder(h1,h2);
wD=0; %watchdog if the game is stuck
while game==1 %while the game is on
    if playerTurn==1 %Human player
       % hand=h1;
        disp('Your turn begins:') %at the beginning of the human's turn
        if table~=0 %if the table has dominoes on it
            disp('Tiles on the table:') %shows your tiles
            for i=1:size(table,2) %for every tile on the table
                fprintf('[%d|%d]', d(table(i),order(table(i),1)), d(table(i),order(table(i),2))) %prints the tiles on the table, according to the order
            end
            fprintf('\n') %carriage return
        else
            disp('You start the game') %if the table is clear, you can start
        end
        %Check if human can play
        if selectToken(h1, fringe) ~=0
            disp('Your tiles:')
            for i=1:size(h1,2)
                fprintf('%d: [%d|%d] ', i, d(h1(i),1), d(h1(i),2))
            end
            
            %check if possible
            if table==0
                hD=0; %Has double
                for i=1:size(h1,2) %for each domino in the hand
                    for j=1:size(p,2) %for each pair in the game
                        if h1(i)==p(j) %check if there is one
                            hD=1; %there is one
                            iHD=i; %indexHighestDouble
                        end
                    end
                end
                if hD==1
                    fprintf('\n You have to play [%d|%d]\n', d(h1(iHD),1),d(h1(iHD),2))
                    th=h1;
                    [h1, table, fringe, order(th(iHD),:)]=placeToken(h1, table, fringe, iHD);
                else
                    token=input('\n What tile do you want to play?\n');
                    if token<=size(h1,2)
                        th=h1; %temphand in case of out-of-index
                        [h1, table, fringe, order(th(token),:)]=placeToken(h1, table, fringe, token);
                    else
                        disp('Sorry, you cannot play that')
                        while token>size(h1,2)
                            token=input('\n What tile do you want to play?\n');
                        end
                    end %add while loop
                end
            else
                token=input('\n What tile do you want to play?\n');
                if token<=size(h1,2)&&(d(h1(token),1)==fringe(1)||d(h1(token),2)==fringe(1)||d(h1(token),2)==fringe(2)||d(h1(token),1)==fringe(2))
                    th=h1; %temphand in case of out-of-index
                    [h1, table, fringe, order(th(token),:)]=placeToken(h1, table, fringe, token);
                else
                    disp('Sorry, you cannot play that')
                    while token>size(h1,2)||(d(h1(token),1)~=fringe(1)&&d(h1(token),2)~=fringe(1)&&d(h1(token),2)~=fringe(2)&&d(h1(token),1)~=fringe(2))
                        token=input('\n What tile do you want to play?\n');
                    end
                end %add while loop
            end
        else
            disp('You have to pick a tile')
            [h1, deck]=pick(h1, deck);
        end
    else %AI player
        %hand=h2;
        disp('Computer''s turn')
        token=selectToken(h2, fringe);
        if token==0
            [h2, deck]=pick(h2, deck);
            wD=wD+1;
            disp('I am picking a tile')
        else
            fprintf('I am placing tile [%d|%d]\n', d(h2(token),1),d(h2(token),2))
            th=h2;
            [h2, table, fringe, order(th(token),:)]=placeToken(h2, table, fringe, token);
            wD=0;
        end
    end
    
    fprintf('------------------\n')
    if size(h1,2)==0
        game=0;
        disp('You won!')       
    end
    if size(h2,2)==0
        game=0;
        disp('Computer won...')
    end
    if playerTurn==1
        playerTurn=2;
    else
        playerTurn=1;
    end
    %fprintf('fringe: %d | %d\n', fringe(1), fringe(2))
    if wD>=2 && size(deck,2)==0
        game=0;
        disp('The game is over')
        sp1=countScore(h1);
        sp2=countScore(h2);
        if sp1<sp2
            disp('You won!')
        else
            disp('Computer won...')
        end
    end
end


function first=playOrder(h1, h2)
%determine the order of the game according to the distribution
%h1 the player 1's hand
%h2 the player 2's hand
first=0;
[~, p]=initTiles(); %get the pairs
for j=1:7 %for each double
    for i=1:7 %for each domino in hand
        if h1(i)==p(j) %is the domino a double ?
            first=1;
        end
        if h2(i)==p(j)
            first=2;
        end
    end
end

if first==0 %if no one has a double
    for i=2:27%from 0|1 to 5|6
        for j=1:7 %for each domino in the hand
            if h1(j)==i
                first=1;
            end
            if h2(j)==i
                first=2;
            end
        end
    end
end
end

function [index] = selectToken(h, f)
%return the selected token (relative index)
%h the hand to choose from
%f the current fringe
d=initTiles();
index=0;
indexa=0;
po=0; %number of possibility
if f(1)~=-1 %if the fringe is different from NULL
    for i=1:size(h, 2)%for each domino of the hand
        for j=1:2 %for each side of the domino
            if f(1)~=f(2)
                for k=1:2 %for each side of the fringe
                    if d(h(i),j)==f(k)
                        po=po+1;
                        indexa(po)=i; %array of index of possibilities
                    end
                end
            else
                if d(h(i),j)==f(1)
                    po=po+1;
                    indexa(po)=i; %array of index of possibilities
                end
            end
        end
    end
    if po~=0
        for i=1:size(indexa,2)
            score(i)=countScore(h(indexa(i)));
        end
        [~,ihs]=max(score); %ihs index of the highest score
        for i=1:size(h,2)
            if h(i)==h(indexa(ihs))
                index=i;
            end
        end
    end      
else
    [~,index]=max(h); %heuristic
end

end

function [hand, table, fringe, order]=placeToken(h, t, f, i) %from hand to deck
%place a token on the table
%h the hand to place from
%t the table
%f the fringe
%i the index of the domino to place
d=initTiles();
order=[1 2];
d1=d(h(i),1);
d2=d(h(i),2);
if t~=0
    f1=f(1);
    f2=f(2);
    if d1==f1 %if the left-hand part of the fringe is the same as the left-hand side of the tile
        f1=d2;
        table = [h(i) t];
        order=[2 1];
    else
        if d1==f2
            f2=d2;
            table = [t h(i)];
            order=[1 2];
        else
            if d2==f1
                f1=d1;
                table = [h(i) t];
                order=[1 2];
            else
                if d2==f2
                    f2=d1;
                    table = [t h(i)];
                    order=[2 1];
                end
            end
        end
    end
    fringe=[f1, f2];
    
else
    table=h(i);
    fringe=d(h(i),:);
end
hand = h;
hand(i)=[];
end

function [hand, deck]=pick(h, d)
%pick a domino from the stack
%h hand to supply
%d deck to pick from

deck=d;
hand=h;
if size(deck,2)~=0
    idom=randi(size(d,2));%index of a random domino
    dom=d(idom); %random domino from the stack
    hand=[h dom]; %the domino is added to the hand
    deck(idom)=[]; %the domino is removed from the deck
end
end

function [sp] = countScore(h)
%Count the score of a player
%h1 the hand of the player
sp=0; %score player
d=initTiles();
for i=1:size(h,2)
    for j=1:2
        sp=sp+d(h(i),j);
    end
end
end

function [h1, h2, deck] = distrib()
%distribute the dominoes between two players
indexH=1; %index for the hands
indexD=1; %index for the deck
h1=zeros(1,6); %init hand 1
h2=h1;  %init hand 2
deck=zeros(1,28-14);
used = zeros(1,16); %used dominoes
while indexH~=8 %while the hand is not full
    flag=1; %flag for placing token in hand
    ih1=randi(28); %first hand
    ih2=randi(28); %second hand
    while ih2==ih1 %if second token same as first
        ih2=randi(28); %redo
    end
    
    for i=1:size(used,2) %for each used token
        if used(i)==ih1 || used(i)==ih2 %we test
            flag=0; %and block the progression
            break %maybe dispensable
        end
    end
    if flag==1 %if there is no double
        h1(indexH)=ih1; %hand placement
        h2(indexH)=ih2; %idem
        used(indexH)=ih1; %add to the list
        used(indexH+7)=ih2; %idem
        indexH=indexH+1; %increment the index
    end
end
%deck
for i=1:28 %for each domino of the game
    flagD=1;
    for j=1:7
        if h1(j)==i || h2(j)==i %if the domino is in one hand
            flagD=0; %it doesn't go in the deck
        end
    end
    if flagD==1 %if it goes in the deck
        deck(indexD)=i; %it is added
        indexD=indexD+1;
    end
end
end

function [d, p] = initTiles()
%initialize the game
n=1;
d=zeros(24,2);
p=zeros(1,7);
while n<28
    for i=0:6
        for j=i:6
            d(n,:)=[i,j]; %list of dominoes
            if i==j
                p(i+1)=n; %list of pairs
            end
            n=n+1;
        end
    end
end
end
