class Match
    attr_accessor :oddsHomeWin,
    :oddsAwayWin, :oddsDraw, :matchStarted,
    :matchEnded, :matchResult,
    :homeTeam, :awayTeam, :winningOdds, :bets

    def startMatch()
        @matchStarted = true
        notify_observers
    end

    def endMatch()
        if @matchStarted == true
            if @matchEnded == true
                puts "Error: match already ended"
            else
                @matchEnded = true
                oddsTotal = @oddsHomeWin + @oddsDraw + @oddsAwayWin
                winner = 1 + rand(oddsTotal)
                if winner < @oddsHomeWin
                    #the winner is home
                    puts "Home (#{homeTeam}) wins"
                    @winningOdds = @oddsHomeWin
                    @matchResult = @homeTeam
                elsif winner > @oddsHomeWin and winner < (@oddsHomeWin + @oddsDraw)
                    #draw
                    puts "Draw"
                    @winningOdds = @oddsDraw
                    @matchResult = "Draw"
                else
                    puts "Away (#{awayTeam}) wins"
                    @winningOdds = @oddsAwayWin
                    @matchResult = @awayTeam
                end
                notify_observers
            end
        else
            puts "Error: match has not started"
        end
    end

    def initialize
        @observers = []
        @oddsHomeWin = 5
        @matchStarted = false
        @matchEnded = false
        @bets = []
    end

    def attach_observer(observer)
        @observers.push observer
    end

    def detach_observer(observer)
        @observers.remove observer
    end

    def notify_observers
        @observers.each { |observer| observer.update(self) }
    end
end
 
class Player
    attr_accessor :balance, :activeBet

    def winnings(odds, money_bet)
        return odds*money_bet
    end

    def initialize
        @balance = 0
        @activeBet = false
    end

    def bet(match, event, amount)
        if not match.matchStarted and not match.matchEnded and withdraw(amount) == true
            case event
            when 1
                eventOdds = match.oddsHomeWin
            when 2
                eventOdds = match.oddsDraw
            when 3
                eventOdds = match.oddsAwayWin
            end
            newBet = Bet.new
            newBet.amount = amount
            newBet.event = event
            newBet.eventOdds = eventOdds
            newBet.homeTeam = match.homeTeam
            newBet.awayTeam = match.awayTeam
            match.bets.push newBet
            @activeBet = newBet
            puts "Bet successful"
        else
            puts "Betting error: match is underway, over, or not enough balance"
        end
    end
    
    def deposit(amount)
        @balance += amount
    end
    
    def withdraw(amount)
        puts amount
        if @balance >= amount
            @balance -= amount
            return true
        else
            puts "Error withdrawing: not enough balance"
            return false
        end
    end

    def update(match_updated)
        if match_updated.matchStarted == true and match_updated.matchEnded == false
            puts "The match #{match_updated.homeTeam} vs #{match_updated.awayTeam} has started"
        end

        if match_updated.matchStarted == true and match_updated.matchEnded == true
            puts "The match #{match_updated.homeTeam} vs #{match_updated.awayTeam} has ended"
            
            if @activeBet.homeTeam == match_updated.homeTeam and @activeBet.awayTeam == match_updated.awayTeam and @activeBet.event == match_updated.matchResult and @activeBet.amount > 0
                @balance += winnings(match_updated.winningOdds, @activeBet.amount)
                puts "Bet won"
            elsif @activeBet.homeTeam == match_updated.homeTeam and @activeBet.awayTeam == match_updated.awayTeam
                puts "Bet lost"
            else
                "No bet for this match."
            end
        
        end
    end
end

class FraudDetector
#player bets >= 100000 on match with odds >= 2

    def update(match_updated)
        match_updated.bets.each{ |bet| 
        if  bet.amount >= 1000000
            if bet.eventOdds >= 2
                puts "Fraud detected ⚠️"
            end
        end
    }
    end
end

class Bet
    attr_accessor :amount, :event, :eventOdds, :homeTeam, :awayTeam
end


matches = []

match1 = Match.new
match1.homeTeam = "Rostov"
match1.awayTeam = "Manchester United"
match1.oddsHomeWin = 5.25
match1.oddsDraw = 3.40
match1.oddsAwayWin = 1.83

matches.push match1


match2 = Match.new
match2.homeTeam = "Celta Vigo"
match2.awayTeam = "Krasnodar"
match2.oddsHomeWin = 1.57
match2.oddsDraw = 4.00
match2.oddsAwayWin = 7.00

matches.push match2

match3 = Match.new
match3.homeTeam = "Lyon"
match3.awayTeam = "Roma"
match3.oddsHomeWin = 2.10
match3.oddsDraw = 3.75
match3.oddsAwayWin = 3.50

matches.push match3

match4 = Match.new
match4.homeTeam = "Olympiacos"
match4.awayTeam = "Besiktas"
match4.oddsHomeWin = 2.55
match4.oddsDraw = 3.20
match4.oddsAwayWin = 3.10

matches.push match4


playerA = Player.new
fraudDetector = FraudDetector.new

puts "Matches on the books:"
puts "odds/Home\t\tDraw\t\tAway/Odds"
i = 1
matches.each do |match|
    match.attach_observer(playerA)
    match.attach_observer(fraudDetector)
    puts "#{i}: #{match.oddsHomeWin}/#{match.homeTeam}\t\t#{match.oddsDraw}\t\t#{match.awayTeam}/#{match.oddsAwayWin}"
    i += 1
end


help = "Commands: (w)ithdraw/(d)eposit/(ba)lance/(b)et/(s)tart match/(e)nd match/(q)uit"

puts help
while command = gets.chomp
    case command
    when "w"
        puts "Please enter amount to withdraw: "
        amount = gets.chomp.to_f
        playerA.withdraw(amount)
        #puts "#{amount} withdrawn successfully"
        puts "Balance: #{playerA.balance}"
    when "ba"
        puts "Balance: #{playerA.balance}"
    when "d"
        puts "Please neter amount to deposit: "
        amount = gets.chomp.to_f
        playerA.deposit(amount)
        puts "#{amount} deposited successfully"
        puts "Balance: #{playerA.balance}"
    when "b"
        puts "Please enter the match number (1-4):"
        match_num = gets.to_i - 1
        puts "Please enter the event type (1-3)."
        puts "1: Home 2: Draw 3: Away"
        bet_event = gets.to_i
        puts "Please enter the amount to bet: "
        bet_amount = gets.chomp.to_f
        
        playerA.bet(matches[match_num], bet_event, bet_amount)
        puts "Balance: #{playerA.balance}"
    when "s"
        puts "Please enter the match number (1-4) to start:"
        match_num = gets.to_i - 1
        matches[match_num].startMatch
        puts "You must now decide when to end the match."
    when "e"
        puts "Please enter the match number (1-4) to end:"
        match_num = gets.to_i - 1
        matches[match_num].endMatch
    when "q"
        exit
    else
      puts "Invalid command!"
end
puts help
end
