import { GameState, Player } from "@/types";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
// import { ScrollArea } from "@/components/ui/scroll-area";

interface DayViewProps {
    gameState: GameState;
    myPlayer: Player;
    onAction: (type: string, payload: any) => void;
}

export function DayView({ gameState, myPlayer, onAction }: DayViewProps) {
    const alivePlayers = gameState.players.filter(p => p.isAlive);
    // const deadPlayers = gameState.players.filter(p => !p.isAlive);

    return (
        <div className="min-h-screen bg-slate-100 p-4 flex items-center justify-center">
            <Card className="w-full max-w-md bg-white">
                <CardHeader>
                    <CardTitle className="text-center text-2xl text-slate-900">Le Village se réveille</CardTitle>
                </CardHeader>
                <CardContent className="space-y-6">
                    <div>
                        <h3 className="font-bold text-lg mb-2">Survivants ({alivePlayers.length})</h3>
                        <div className="flex flex-wrap gap-2">
                            {alivePlayers.map(p => (
                                <span key={p.id} className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm font-medium">
                                    {p.name}
                                </span>
                            ))}
                        </div>
                    </div>

                    {/* Show only players who died LAST NIGHT */}
                    {gameState.lastNightDeadIds && gameState.lastNightDeadIds.length > 0 ? (
                        <div>
                            <h3 className="font-bold text-lg mb-2 text-red-600">Morts cette nuit</h3>
                            <div className="flex flex-wrap gap-2">
                                {gameState.players
                                    .filter(p => gameState.lastNightDeadIds.includes(p.id))
                                    .map(p => (
                                        <span key={p.id} className="px-3 py-1 bg-red-100 text-red-800 rounded-full text-sm font-medium">
                                            {p.name}
                                        </span>
                                    ))}
                            </div>
                        </div>
                    ) : (
                        <div>
                            <h3 className="font-bold text-lg mb-2 text-slate-500">Morts cette nuit</h3>
                            <p className="text-slate-400 italic">Aucun mort</p>
                        </div>
                    )}

                    <div className="pt-4 border-t">
                        <p className="text-center text-slate-600 mb-4">C'est le moment du débat. Qui est le Loup-Garou ?</p>
                        {myPlayer.isAlive ? (
                            <Button className="w-full text-lg py-6" onClick={() => onAction('START_VOTE', {})}>
                                Lancer le Vote
                            </Button>
                        ) : (
                            <p className="text-center italic text-slate-400">Les morts ne parlent pas.</p>
                        )}
                    </div>
                </CardContent>
            </Card>
        </div>
    );
}
