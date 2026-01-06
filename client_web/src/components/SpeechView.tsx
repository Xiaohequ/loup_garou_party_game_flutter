import { GameState, Player } from "@/types";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

interface SpeechViewProps {
    gameState: GameState;
    myPlayer: Player;
    onAction: (type: string, payload: any) => void;
}

export function SpeechView({ gameState, myPlayer, onAction }: SpeechViewProps) {
    const accusedId = gameState.accusedPlayerId;
    const isMe = myPlayer.id === accusedId;
    const accusedPlayer = gameState.players.find(p => p.id === accusedId);

    return (
        <div className="min-h-screen bg-slate-900 p-4 flex items-center justify-center">
            <Card className="w-full max-w-md bg-slate-800 border-slate-700 text-white">
                <CardHeader>
                    <CardTitle className="text-center text-2xl text-yellow-500">La Défense</CardTitle>
                </CardHeader>
                <CardContent className="space-y-8 text-center">
                    {isMe ? (
                        <>
                            <div className="text-6xl mb-4">🎤</div>
                            <h3 className="text-2xl font-bold">C'est à vous de parler !</h3>
                            <p className="text-slate-300">
                                Défendez-vous, mentez, pleurez... Faites tout pour survivre.
                            </p>
                            <Button
                                className="w-full bg-red-600 hover:bg-red-700 text-white text-lg py-6 mt-8"
                                onClick={() => onAction('END_SPEECH', {})}
                            >
                                Fin de prise de parole
                            </Button>
                        </>
                    ) : (
                        <>
                            <div className="text-6xl mb-4 animate-pulse">👂</div>
                            <h3 className="text-xl font-bold">Écoutez {accusedPlayer?.name}</h3>
                            <p className="text-slate-300">
                                {accusedPlayer?.name} joue sa survie.
                            </p>
                            <div className="mt-8 p-4 bg-slate-900 rounded text-sm text-slate-500">
                                En attente de la fin du discours...
                            </div>
                        </>
                    )}
                </CardContent>
            </Card>
        </div>
    );
}
