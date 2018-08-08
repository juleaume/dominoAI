clear;
clc;
game=1;
[d, p]=initTiles(); %list of dominoes and pairs CONSTANTS
table=0;
fringe=[-1,-1]; %both ends of the table
[h1, h2, deck]=distrib(); %distribution of the dominoes

[first, second]=playOrder(h1,h2); %decide who is starting player1 player2
%evenTurn=1;
playerTurn=first;
wD=0; %watchdog if the game is stuck
while game==1 %while the game is on
    if playerTurn==1
        hand=h1;
        
    else
        hand=h2;
    end
    fprintf('Player %d', playerTurn)
    token=selectToken(hand, fringe);
    if token==0
        [hand, deck]=pick(hand, deck);
        wD=wD+1;
        disp(' is picking a tile')
    else
        [hand, table, fringe]=placeToken(hand, table, fringe, token);
        wD=0;
        fprintf(' is placing tile [%d | %d]\n', d(table(size(table,2)),1),d(table(size(table,2)),2))
    end
    fprintf('------------------\n')
    if size(hand,2)==0
        game=0;
        fprintf('game won by player %d\n', playerTurn)
        
    end
    if playerTurn==1
        h1=hand;
        playerTurn=2;
    else
        h2=hand;
        playerTurn=1;
    end
    fprintf('fringe: %d | %d\n', fringe(1), fringe(2))
    if wD>=2 && size(deck,2)==0
        game=0;
        disp('The game is over')
        sp1=countScore(h1);
        sp2=countScore(h2);
        if sp1<sp2
            disp('Player 1 winner')
        else
            disp('Player 2 winner')
        end
    end
end


function [first, second]=playOrder(h1, h2)
%determine the order of the game according to the distribution
%h1 the player 1's hand
%h2 the player 2's hand
first=0;
[~, p]=initTiles();
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
if first == 1
    second = 2;
else
    second =1;
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

function [hand, table, fringe]=placeToken(h, t, f, i) %from hand to deck
%place a token on the table
%h the hand to place from
%t the table
%f the fringe
%i the index of the domino to place
d=initTiles();

d1=d(h(i),1);
d2=d(h(i),2);
if t~=0
    table = [t h(i)];
    f1=f(1);
    f2=f(2);
    if d1==f1
        f1=d2;
    else
        if d1==f2
            f2=d2;
        else
            if d2==f1
                f1=d1;
            else
                if d2==f2
                    f2=d1;
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
