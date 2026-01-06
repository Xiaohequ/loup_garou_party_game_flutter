import { GameState, Player } from "@/types";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ScrollArea } from "@/components/ui/scroll-area";

interface VoteViewProps {
    gameState: GameState;
    myPlayer: Player;
    onAction: (type: string, payload: any) => void;
}

export function VoteView({ gameState, myPlayer, onAction }: VoteViewProps) {
    const alivePlayers = gameState.players.filter(p => p.isAlive);
    const myVote = gameState.votes[myPlayer.id];

    if (!myPlayer.isAlive) {
        return (
            <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
                <div className="text-center text-white">
                    <h1 className="text-2xl font-bold mb-2">Vote en cours...</h1>
                    <p className="text-slate-400">Vous êtes mort, vous ne pouvez pas voter.</p>
                </div>
            </div>
        )
    }

    return (
        <div className="min-h-screen bg-slate-100 p-4 flex items-center justify-center">
            <Card className="w-full max-w-md bg-white">
                <CardHeader>
                    <CardTitle className="text-center text-2xl text-slate-900">Vote d'élimination</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                    <p className="text-center text-slate-600">Choisissez qui éliminer du village.</p>
                    <ScrollArea className="h-[300px] pr-4">
                        <div className="grid grid-cols-1 gap-2">
                            {alivePlayers.map(p => {
                                const isSelected = myVote === p.id;
                                return (
                                    <Button
                                        key={p.id}
                                        variant={isSelected ? "default" : "outline"}
                                        className={`justify-between ${isSelected ? 'bg-red-600 hover:bg-red-700' : ''}`}
                                        onClick={() => onAction('DAY_VOTE', { targetId: p.id })}
                                    >
                                        {p.name}
                                        {isSelected && <span className="ml-2 font-bold">(Votre choix)</span>}
                                    </Button>
                                );
                            })}
                        </div>
                    </ScrollArea>
                    <p className="text-xs text-center text-slate-400 mt-4">
                        Le vote se termine quand tout le monde a voté.
                    </p>
                </CardContent>
            </Card>
        </div>
    );
}
