%Game of dominoes, 1-3 computers against 1 human
clear;
clc;

[d, p]=initTiles(); %list of dominoes and pairs CONSTANTS
nbStudy=0;
scoreAIf=0;
scoreRndf=0;
mnf=0;
while nbStudy<10
    nbGame=0;
    scoreAI=0;
    scoreRnd=0;
    mn=0;
    while nbGame<10000
        game=1;
        table=0;
        fringe=[-1,-1]; %both ends of the table
        [h1, h2, deck]=distrib(2); %distribution of the dominoes
        order=[ones(28,1) 2*ones(28,1)];
        turnOrder=playOrder(h1,h2);
        wD=0; %watchdog if the game is stuck
        while game==1 %while the game is on
            switch turnOrder
                case 1
                    ch=h1;
                case 2
                    ch=h2;
            end
            %fprintf('Computer %d turn\n', turnOrder)
            if turnOrder==1
                %token=randomToken(ch, fringe);
                token=selectToken(ch, fringe);
            else
                %token=selectToken2(ch, fringe);
                token=randomToken(ch, fringe);
            end
            if token==0
                [ch, deck]=pick(ch, deck);
                wD=wD+1;
                %disp('I am picking a tile')
            else
                %fprintf('I am placing tile [%d|%d]\n', d(ch(token),1),d(ch(token),2))
                th=ch;
                [ch, table, fringe, order(th(token),:)]=placeToken(ch, table, fringe, token);
                wD=0;
            end
            switch turnOrder
                case 1
                    h1=ch;
                case 2
                    h2=ch;
            end
            %fprintf('------------------\n')
            if size(h1,2)==0
                scoreAI=scoreAI+1;
                game=0;
            end
            if size(h2,2)==0
                scoreRnd=scoreRnd+1;
                game=0;
            end
            turnOrder=mod(turnOrder,2)+1; %becomes 1 if 2 and 2 if 1
            %fprintf('fringe: %d | %d\n', fringe(1), fringe(2))
            if wD>=2 && size(deck,2)==0
                game=0;
                %disp('There are no more tile to pick')
                sp1=countScore(h1);
                sp2=countScore(h2);
                if sp1<sp2
                    scoreAI=scoreAI+1;
                else
                    if sp1>sp2
                        scoreRnd=scoreRnd+1;
                    else
                        mn=mn+1;
                    end
                end
            end
        end
        nbGame=nbGame+1;
    end
    nbStudy=nbStudy+1;
    scoreAIf=scoreAIf+scoreAI;
    scoreRndf=scoreRndf+scoreRnd;
    mnf=mnf+mn;
end
scoreAIf=scoreAIf/nbStudy;
scoreRndf=scoreRnd/nbStudy;
mnf=mnf/nbStudy;
disp(scoreAIf);
disp(scoreRnd);
disp(mnf);

function first=playOrder(h1, h2)
%determine the order of the game according to the distribution
%h1 the player 1's hand
%h2 the player 2's hand
first=0;
[d, p]=initTiles(); %get the pairs
for j=1:size(p,2) %for each double
    for i=1:size(h1,2) %for each domino in hand
        if h1(i)==p(j) %is the domino a double ?
            first=1;
        end
        if h2(i)==p(j)
            first=2;
        end
    end
end
if first==0 %if no one has a double
    sum1=[];
    sum2=[];
    for i=1:size(h1,2) %for each domino in the hands
        sum1=[sum1, d(h1(i),1)+d(h1(i),2)];
        sum2=[sum2, d(h2(i),1)+d(h2(i),2)];
    end
    if max(sum1)<max(sum2)
        first=2;
    else
        first=1;
    end
end
end

function [index] = selectToken(h, f) %v3.0
%return the selected token (relative index)
%h the hand to choose from
%f the current fringe
d=initTiles();
index=0; %index to be returned
indexa=[];
scorea=[];
hs=0;
if f(1)==-1 %if the fringe is void
    for i=1:size(h,2) %for each domino in the hand
        if d(h(i),1)==d(h(i),2) %if there is a pair
            indexa=[indexa, i]; %add it to the possibilities
        end
    end
    if size(indexa,2)>0
        hs=max(h(indexa));
    else %if there is no double
        hs=max(h);
    end
    for i=1:size(h,2)
        if h(i)==hs
            index=i;
            break
        end
    end
else
    for i=1:size(f,2) %for each side of the fringe
        for j=1:size(h,2) %for each domino in the hand
            for k=1:2 %for each side of the domino
                if d(h(j),k)==f(i) %if the side of the domino corresponds to the side of the fringe
                    indexa=[indexa, j]; %add the possibility to the array of possibilities
                    scorea=[scorea, d(h(j),1)+d(h(j),2)]; %add the score of this turn
                    for di=1:size(h,2) %for each remaining domino
                        %if we are not looking at the same domino and if there is a match
                        if di~=j && (d(h(j),mod(k,2)+1)==d(h(di),1) || d(h(j),mod(k,2)+1)==d(h(di),2))
                            score=d(h(j),1)+d(h(j),2)+d(h(di),1)+d(h(di),2); %count the score of this turn and next turn
                            if score>hs %if the score is higher
                                hs=score; %take its place
                                index=j; %mark the index
                            end
                        end
                    end
                end
            end
        end
    end
    if index==0 %if there is no possibility next turn
        if size(indexa,2)>0 %if there is a possibility to play
            [~,ihs]=max(scorea);
            index=indexa(ihs);
        end
    end
end
return
end

function [index] = selectToken2(h, f) %v2.1
%return the selected token (relative index)
%h the hand to choose from
%f the current fringe
d=initTiles();
index=0; %index to be returned
indexa=0;%index of potential return
sided=[]; %side of the domino being used
sidef=[]; %side of the fringe being used
po=0; %number of possibility
nextTurn=[]; %if a move next turn is possible
flagTurn=0; %flag for condition
score=[];%score of each possible move
placeable=[]; %array of every placeable dominoes for next turn
if f(1)~=-1 %if the fringe is different from NULL
    for i=1:size(h, 2)%for each domino of the hand
        for j=1:2 %for each side of the domino
            if f(1)~=f(2)
                for k=1:2 %for each side of the fringe
                    if d(h(i),j)==f(k)
                        po=po+1;
                        indexa(po)=i; %array of index of possibilities
                        sided(po)=j;
                        sidef(po)=k;
                    end
                end
            else %if both side of the fringe are the same
                if d(h(i),j)==f(1)
                    po=po+1;
                    indexa(po)=i; %array of index of possibilities
                    sided(po)=j;
                    sidef(po)=1;
                end
            end
        end
    end
    if po~=0%if there is a possibility
        for i=1:size(indexa,2)%for each playable domino
            for j=1:size(h,2)%for each remaining domino in the hand
                if j~=indexa(i) %if we are not looking at the same
                    for k=1:2 %for each side of the domino
                        if sided(i)==1 %look at left side
                            if d(h(indexa(i)),2)==d(h(j),k)%if there is a match
                                flagTurn=1;
                            end
                        else
                            if sided(i)==2 %look at right side
                                if d(h(indexa(i)),1)==d(h(j),k)%there is a match
                                    flagTurn=1;
                                end
                            end
                        end
                    end
                    if flagTurn==1
                        placeable=[placeable, indexa(i)];
                        nextTurn=[nextTurn, h(j)];
                        flagTurn=0;
                    end
                end
            end
        end
        if size(placeable,1)==0 %if there is no next turn
            for i=1:size(indexa,2)
                score(i)=countScore(h(indexa(i)));
            end
            [~,ihs]=max(score); %ihs index of the highest score
            for i=1:size(h,2)
                if h(i)==h(indexa(ihs))
                    index=i;
                end
            end
        else
            scoreNextTurn=zeros(size(placeable));
            for i=1:size(placeable,2)
                scoreNextTurn(i)=d(h(placeable(i)),1)+d(h(placeable(i)),2)+d(nextTurn(i),1)+d(nextTurn(i),2);
            end
            [~,maxIndex]=max(scoreNextTurn); 
            index=max(placeable(maxIndex));
        end
    end
else
    [~,index]=max(h); %heuristic
end
end

function [index] = selectToken3(h, f) %v1.2
%return the selected token (relative index)
%h the hand to choose from
%f the current fringe
d=initTiles();
index=0;
indexa=[];
score=0;
hs=0;
if f(1)~=-1 %if the fringe is different from NULL
    for i=1:size(h, 2)%for each domino of the hand
        for j=1:2 %for each side of the domino
            for k=1:2 %for each side of the fringe
                if d(h(i),j)==f(k)
                    score=d(h(i),1)+d(h(i),2);
                    if score>hs
                        hs=score;
                        index=i;
                    end
                end
            end
        end
    end      
else
    for i=1:size(h,2) %for each domino in the hand
        if d(h(i),1)==d(h(i),2) %if there is a pair
            indexa=[indexa, i]; %add it to the possibilities
        end
    end
    if size(indexa,2)>0
        [~, ihs]=max(h(indexa));
    else %if there is no double
        hs=max(h);
        for i=1:size(h,2)
            if h(i)==hs
                index=i;
                return
            end
        end
    end
    index=indexa(ihs);
    return
end
end

function index = randomToken(h,f)%v1.1
d=initTiles();
indexa=[];
index=0;
if f(1)~=-1
    for i=1:size(f,2) %for each tile in the fringe
        for j=1:size(h,2) %for each domino in  the hand
            for k=1:2 %for each side of the domino
                if d(h(j),k)==f(1) || d(h(j),k)==f(2) %if there is a match
                    indexa=[indexa j]; %add to the list of possibilities the domino
                end
            end
        end
    end
    if size(indexa,2)>0
        index=indexa(randi(size(indexa,2)));
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
    sp=sp+d(h(i),1)+d(h(i),2);
end
end

function [h1, h2, deck] = distrib(n)
%distribute the dominoes between n players
indexH=1; %index for the hands
indexD=1; %index for the deck
nbdom=7;

h1=zeros(1,nbdom); %init hand 1
h2=h1;  %init hand 2

deck=zeros(1,28-n*nbdom);
used = zeros(1,n*nbdom); %used dominoes
while indexH<=nbdom %while the hand is not full
    flag=1; %flag for placing token in hand
    ih1=randi(28); %first hand
    ih2=randi(28); %second hand
    
    while ih2==ih1 %if second token same as first
        ih2=randi(28); %redo
    end
    
    for i=1:size(used,2) %for each used token
        if used(i)==ih1 || used(i)==ih2%we test
            flag=0; %and block the progression
            break %maybe dispensable
        end
    end
    if flag==1 %if there is no double placement
        h1(indexH)=ih1; %hand placement
        used(indexH)=ih1; %add to the list
        h2(indexH)=ih2; %idem
        used(indexH+n*nbdom)=ih2; %idem
        indexH=indexH+1; %increment the index
    end
end
%deck
for i=1:28 %for each domino of the game
    flagD=1;
    for j=1:nbdom
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
