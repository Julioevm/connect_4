import sequtils, tables, strutils, strformat, random, os, parseopt, math

randomize()

let nextPlayer = {"X":"O", "O":"X"}.toTable
const 
    rows = 6
    cols = 7
    connect = 4
    up = -7
    down = 7 
    left = -1
    right = 1

type
    Board = ref object of RootObj
        grid: array[42, string]
        columnPos: array[7, int]
        lastMove: int
        playerXMoves: seq[int]
        playerOMoves: seq[int]

proc newBoard(): Board =
    var board  = Board()
    board.grid = ["·", "·", "·", "·", "·", "·", "·",
                  "·", "·", "·", "·", "·", "·", "·",
                  "·", "·", "·", "·", "·", "·", "·",
                  "·", "·", "·", "·", "·", "·", "·",
                  "·", "·", "·", "·", "·", "·", "·",
                  "·", "·", "·", "·", "·", "·", "·"]
    board.columnPos = [35, 36, 37, 38, 39, 40, 41]
    board.lastMove = 0
    return board

proc done(this: Board, player: string): (bool, string) =
    var isConnected = true
    var connections = 0

    # Horizontal
    for x in 0..<cols - connect:
        for y in 0..<rows:
            let spot = 7 * y + x
            for z in spot..spot + connect:
                if this.grid[z] == player:
                    isConnected = true
                    connections += 1
                else:
                    isConnected = false
                    connections = 0
                    break
                if connections == connect:                        
                    echo "Connected " & $connect
                    return (isConnected, player)

    # Vertical
    for x in 0..cols:
        for y in 0..rows - connect:
            connections = 0
            let spot = (7 * y) + x
            let verticalLimit = (spot + ((connect - 1 ) * cols)) - 1
            for z in countUp(spot, verticalLimit, cols):
                if this.grid[z] == player:
                    isConnected = true
                    connections += 1
                else:
                    isConnected = false
                    connections = 0
                    break
                if connections == connect:                        
                    echo "Connected " & $connect
                    return (isConnected, player)

    # Diagonals
    for x in 0..<cols:
        for y in 0..<rows:
            connections = 0
            let spot = (cols * y) + x
            # Left - Right
            let leftRightLimit = (cols * ((cols - x ) - y )) - 1
            for z in countUp(spot, leftRightLimit, down + right):
                if z > (cols * rows): break
                if this.grid[z] == player:
                    isConnected = true
                    connections += 1
                else:
                    isConnected = false
                    connections = 0
                if connections == connect:                        
                    echo "Connected " & $connect
                    return (isConnected, player)
            # Right - Left
            let rightLeftLimit = (spot + (rows * ( rows - (y + 1)))) - 1
            for z in countUp(spot, rightLeftLimit, down + left):
                if z > (cols * rows): break
                echo z
                if this.grid[z] == player:
                    isConnected = true
                    connections += 1
                else:
                    isConnected = false
                    connections = 0
                if connections == connect:                        
                    echo "Connected " & $connect
                    return (isConnected, player)

    return (isConnected, player)

proc `$`(this:Board): string =
    echo ("1 2 3 4 5 6 7")
    for i in 0..high(this.grid):
        stdout.write(this.grid[i] & " ")
        if (i + 1) mod 7 == 0 : stdout.write("\n")

type 
    Move = tuple[score: int, pos: int, depth: int]

proc `<` (a, b: Move): bool =
    return a.score < b.score

type
    Game = ref object of RootObj
        currentPlayer*: string
        board*: Board
        aiPlayer*: string
        difficulty*: int

proc newGame(aiPlayer:string="", difficulty:int=9): Game =
    var game = new Game

    game.board = newBoard()
    game.currentPlayer = "X"
    game.aiPlayer = aiPlayer
    game.difficulty = difficulty

    return game

    # 1 2 3 4 5 6 7
    # · · · · · · ·
    # · · · · · · ·
    # · · · · · · ·
    # · · · · · · ·
    # · · · · · · ·
    # · · · · · · ·

proc changePlayer(this:Game) : void =
    this.currentPlayer = nextPlayer[this.currentPlayer]

proc getAvailableMoves(this: Board) : seq[int] =
    var availableCol = newSeq[int]()
    for i in 0..high(this.columnPos):
        if this.columnPos[i] > cols - 1:
            availableCol.add(i)
    
    return availableCol

proc enterMove(move: int, this: Board, player: string) : bool =
    let move = move - 1
    # Set the chip on the colum at the right spot.

    if move >= 0 and move < cols and this.columnPos[move] >= 0:
        let spot = this.columnPos[move]
        this.grid[spot] = player
        # Keep track of each players moves
        if (player == "X"):
            this.playerXMoves.add(spot)
        else:
            this.playerOMoves.add(spot)

        this.columnPos[move] += up
        return true
    else: 
        echo ("Invalid move")
        return false

# todo proc getBestMove()

proc writeHelp() =
    echo """
    Connect 4 0.0.2
    Set the value for the argument with = or :
        connect_4 -a=O -l=9
    Arguments:
        -h | --help    : This screen
        -a | --ai      : AI player [X or O]
        -l | --level   : Difficulty level 9 (High) to 0 (Low)
    """

proc startGame*(this:Game): void=
    while true:
        echo this.board
        if this.aiPlayer != this.currentPlayer:
            while true:
                stdout.write("Player " & this.currentPlayer & " enter your move: (1-7)")
                let move = stdin.readLine()
                if move.isDigit and enterMove(move.parseInt, this.board, this.currentPlayer): break
        else:
            if this.currentPlayer == this.aiPlayer:
                echo "AI player turn!"
        #        let currentEmptySpots = this.board.availableMoves()
                
        #         if len(currentEmptySpots) <= this.difficulty:
        #             echo "AI move!"
        #             let move = getBestMove(this, this.board, this.aiPlayer)
        #             this.board.list[move.pos] = this.aiPlayer
        #         else:
        #             # Do a random move on an empty spot.
                echo "Random move!"
                while true:
                    if enterMove(cols.rand(), this.board, this.currentPlayer): break
            
            
        let (done, winner) = this.board.done(this.currentPlayer)
        this.changePlayer()
        
        if done:
            echo this.board
            if winner == "tie":
                echo ("TIE!")
            else:
                echo("The winner is: ", winner," !")
            break;
    
proc cli*() =
    var 
        aiplayer = ""
        difficulty = 9

    for kind, key, val in getopt():
        echo val
        case kind
        of cmdArgument, cmdLongOption, cmdShortOption:
            case key 
            of "help", "h":
                writeHelp()
                return
            of "ai", "a":
                echo "AI Player: " & val
                aiplayer = val
            of "level", "l":
                difficulty = parseInt(val)
            else:
                discard
        else:
            discard

    let game = newGame(aiPlayer, difficulty)
    game.startGame()

when isMainModule:
    cli()