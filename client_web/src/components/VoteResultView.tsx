import { GameState, Player } from "@/types";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ScrollArea } from "@/components/ui/scroll-area";

interface VoteResultViewProps {
    gameState: GameState;
    myPlayer: Player;
    onAction: (type: string, payload: any) => void;
}

export function VoteResultView({ gameState, myPlayer, onAction }: VoteResultViewProps) {
    const accusedId = gameState.accusedPlayerId;
    const accusedPlayer = gameState.players.find(p => p.id === accusedId);

    // Group votes by target
    const votesByTarget: Record<string, string[]> = {}; // TargetID -> [VoterNames]
    Object.entries(gameState.votes || {}).forEach(([voterId, targetId]) => {
        const voter = gameState.players.find(p => p.id === voterId);
        if (voter) {
            if (!votesByTarget[targetId]) votesByTarget[targetId] = [];
            votesByTarget[targetId].push(voter.name);
        }
    });

    return (
        <div className="min-h-screen bg-slate-100 p-4 flex items-center justify-center">
            <Card className="w-full max-w-md bg-white">
                <CardHeader>
                    <CardTitle className="text-center text-2xl text-slate-900">Résultats du Vote</CardTitle>
                </CardHeader>
                <CardContent className="space-y-6">
                    {accusedPlayer ? (
                        <div className="text-center">
                            <h3 className="text-xl font-bold mb-2">Les villageois accusent :</h3>
                            <div className="text-3xl font-black text-red-600 mb-4">{accusedPlayer.name}</div>
                            <p className="text-slate-600">
                                {accusedPlayer.name} va maintenant prendre la parole pour sa défense.
                            </p>
                        </div>
                    ) : (
                        <div className="text-center space-y-4">
                            {gameState.voteRound === 1 && gameState.voteCandidates && gameState.voteCandidates.length > 0 ? (
                                <>
                                    <div className="text-amber-600 text-lg font-bold">
                                        Égalité ! <br />
                                        Veuillez départager les candidats.
                                    </div>
                                    <p className="text-sm text-slate-500">
                                        Candidats : {gameState.players.filter(p => gameState.voteCandidates?.includes(p.id)).map(p => p.name).join(", ")}
                                    </p>
                                    <Button
                                        className="w-full bg-amber-600 text-white hover:bg-amber-700"
                                        onClick={() => onAction('START_REVOTE', {})}
                                    >
                                        Revoter
                                    </Button>
                                </>
                            ) : (
                                <>
                                    <div className="text-slate-500 text-lg font-medium">
                                        Égalité parfaite. <br /> Pas d'élimination aujourd'hui.
                                    </div>
                                    <Button
                                        className="w-full bg-slate-800 text-white hover:bg-slate-700"
                                        onClick={() => onAction('VALIDATE_RESULT', {})}
                                    >
                                        Valider et dormir
                                    </Button>
                                </>
                            )}
                        </div>
                    )}

                    <div className="border-t pt-4">
                        <h4 className="font-bold mb-2 text-sm uppercase text-slate-500">Détails des votes</h4>
                        <ScrollArea className="h-[200px]">
                            {Object.entries(votesByTarget).map(([targetId, voters]) => {
                                const isAbstain = targetId === "ABSTAIN";
                                const target = gameState.players.find(p => p.id === targetId);
                                const name = isAbstain ? "Abstentions" : (target?.name || 'Inconnu');

                                return (
                                    <div key={targetId} className="mb-3">
                                        <div className={`font-bold ${isAbstain ? 'text-slate-500 italic' : 'text-slate-800'}`}>
                                            {name} ({voters.length} voix)
                                        </div>
                                        <div className="text-sm text-slate-500">
                                            Voté par : {voters.join(", ")}
                                        </div>
                                    </div>
                                );
                            })}
                        </ScrollArea>
                    </div>

                    <div className="pt-4 border-t mt-4">
                        {myPlayer.id === accusedId ? (
                            <div className="text-center animate-pulse">
                                <h3 className="text-lg font-bold text-red-600 mb-2">À VOUS DE PARLER !</h3>
                                <p className="text-sm text-slate-600 mb-4">Défendez-vous avant le jugement final.</p>
                                <Button
                                    className="w-full bg-red-600 hover:bg-red-700 text-white"
                                    onClick={() => onAction('END_SPEECH', {})}
                                >
                                    Fin de prise de parole
                                </Button>
                            </div>
                        ) : (
                            <div className="text-center text-slate-500">
                                <p className="mb-2">En attente de la fin du discours de {accusedPlayer?.name}...</p>
                                <div className="text-2xl">🤫 👂</div>
                            </div>
                        )}
                    </div>
                </CardContent>
            </Card>
        </div>
    );
}
