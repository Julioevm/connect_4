import tables, strutils, strformat, parseopt, math

let nextPlayer = {"X":"O", "O":"X"}.toTable
const 
    ROWS = 6
    COLS = 7
    CONNECT = 4
    UP = -COLS
    DOWN = COLS 
    RIGHT = 1
    LEFT = -RIGHT

type
    Board = ref object of RootObj
        grid: array[42, string]
        columnPos: array[7, int]
        lastMove: int

type 
    Move = tuple[score: int, pos: int]

type
    Game = ref object of RootObj
        currentPlayer*: string
        board*: Board
        aiPlayer*: string
        difficulty*: int
        score*: int
        round*: int

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

proc done(this: Game, depth: int, score: int): bool =
    return depth <= 0 or score == this.score or score == -this.score

proc score(this: Board, player: string, aiPlayer: string, d = false): int =
    var horizontalPoints = 0
    var verticalPoints = 0
    var diagonalPoints1 = 0
    var diagonalPoints2 = 0

    # Horizontal
    for x in 0..COLS - CONNECT:
        for y in 0..<ROWS:
            var points = 0
            let spot = 7 * y + x
            for z in spot..spot + (CONNECT - 1):
                if this.grid[z] == player:
                    points += 1
            if points == CONNECT:
                if d: echo fmt"horizontal {spot} to {spot + (CONNECT - 1)}" 
                if player == aiPlayer:
                    return 100000
                else:
                    return -100000
            else:
                horizontalPoints += points

    # Vertical
    for x in 0..<COLS:
        for y in 0..ROWS - CONNECT:
            var points = 0
            let spot = (7 * y) + x
            let verticalLimit = (spot + ((CONNECT - 1 ) * DOWN))
            for z in countUp(spot, verticalLimit, DOWN):
                if this.grid[z] == player:
                    points += 1
            if points == CONNECT:                          
                if d: echo fmt"vertical {spot} to {verticalLimit}" 
                if player == aiPlayer:
                    return 100000
                else:
                    return -100000
            else: 
                verticalPoints += points

    # Diagonals
    # Left - Right
    for x in 0..COLS - CONNECT:
        for y in 0..ROWS - CONNECT:
            var points = 0
            let spot = (COLS * y) + x
            let leftRightLimit = spot + ((DOWN + RIGHT) * (CONNECT - 1))
            for z in countUp(spot, leftRightLimit, DOWN + RIGHT):
                if this.grid[z] == player:
                    points += 1
            if points == CONNECT:                         
                if d: echo fmt"leftRight {spot} to {leftRightLimit}"                      
                if player == aiPlayer:
                    return 100000
                else:
                    return -100000
            else:
                diagonalPoints1 += points
    # Right - Left
    for x in CONNECT-1..<COLS:
        for y in 0..ROWS - CONNECT:
            var points = 0
            let spot = (COLS * y) + x
            points = 0
            let rightLeftLimit = (spot + (DOWN + LEFT) * (CONNECT - 1))
            for z in countUp(spot, rightLeftLimit, DOWN + LEFT):
                if z >= (COLS * ROWS): break
                if this.grid[z] == player:
                    points += 1
            if points == CONNECT:                         
                if d: echo fmt"rightLeft {spot} to {rightLeftLimit}" 
                if player == aiPlayer:
                    return 100000
                else:
                    return -100000
            else:
                diagonalPoints2 += points

    return horizontalPoints + verticalPoints + diagonalPoints1 + diagonalPoints2

proc `$`(this:Board): string =
    echo ("1 2 3 4 5 6 7")
    for i in 0..high(this.grid):
        stdout.write(this.grid[i] & " ")
        if (i + 1) mod 7 == 0 : stdout.write("\n")

proc newGame(aiPlayer:string="", difficulty:int=4): Game =
    var game = new Game

    game.board = newBoard()
    game.currentPlayer = "X"
    game.aiPlayer = aiPlayer
    game.difficulty = difficulty
    game.score = 100000
    game.round = 0

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

proc availableMoves(this: Board) : seq[int] =
    var availableCol = newSeq[int]()
    for i in 0..high(this.columnPos):
        if this.columnPos[i] >= COLS:
            availableCol.add(i)
    
    return availableCol

proc enterMove(this: Board, move: int, player: string) : bool =
    # Set the chip on the colum at the right spot.

    if move >= 0 and move < COLS and this.columnPos[move] >= 0:
        let spot = this.columnPos[move]
        this.grid[spot] = player
        this.columnPos[move] += UP
        return true
    else: 
        echo ("Invalid move")
        return false

proc getBestMove(this: Game, board: Board, player: string, depth:int, alpha: int = -99999, beta: int = 99999): Move =
    var score = board.score(player, this.aiPlayer)
    if this.done(depth, score):
        return (score: score, pos: -1)
    
    var max = (-99999, -1)
    var min = (99999, -1)
    var alpha = alpha
    var beta = beta

    for pos in board.availableMoves():
        var newBoard = newBoard()
        deepCopy(newBoard, board)

        discard newBoard.enterMove(pos, player)
        let move = this.getBestMove(newBoard, nextPlayer[player], depth - 1, alpha, beta)

        if player == this.aiPlayer and (move.score > max[0] or max[1] == -1):
            max[0] = move.score
            max[1] = pos
            alpha = move.score
        elif player != this.aiPlayer and (move.score < min[0] or min[1] == -1):
            min[0] = move.score
            min[1] = pos
            beta = move.score
        if alpha >= beta:
            break

    if player == this.aiPlayer:
        return max
    else:
        return min

proc writeHelp() =
    echo """
    CONNECT 4 0.1.0
    Set the value for the argument with = or :
        connect_4 -a=O -l=9
    Arguments:
        -h | --help    : This screen
        -a | --ai      : AI player [X or O]
        -l | --level   : Difficulty level 9 (High) to 0 (Low)
    """

proc startGame*(this:Game): void=
    while true:
        var move: Move
        var score = 0
        this.round += 1
        echo "Round " & $this.round
        echo this.board
        if this.aiPlayer != this.currentPlayer:
            while true:
                stdout.write("Player " & this.currentPlayer & " enter your move: (1-7)")
                let move = stdin.readLine()
                if move.isDigit and this.board.enterMove(move.parseInt - 1, this.currentPlayer): break
        else:
            if this.currentPlayer == this.aiPlayer:
                echo "AI player turn!"
                move = getBestMove(this, this.board, this.aiPlayer, this.difficulty)
                echo "AI plays " & $(move.pos + 1)
                discard this.board.enterMove(move.pos, this.currentPlayer)
    
        score = this.board.score(this.currentPlayer, this.aiPlayer)
        let done = this.done(this.difficulty, score)
        
        if done:
            echo this.board
            if score == this.score:
                echo ("The computer wins!")
            elif score == -this.score:
                echo(fmt"The player {this.currentPlayer} wins!")
            break;

        this.changePlayer()
    
proc cli*() =
    var 
        aiplayer = ""
        difficulty = 9

    for kind, key, val in getopt():
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
                if difficulty > 9: difficulty = 9
                elif difficulty < 0: difficulty = 0
            else:
                discard
        else:
            discard

    let game = newGame(aiPlayer, difficulty)
    game.startGame()

when isMainModule:
    cli()