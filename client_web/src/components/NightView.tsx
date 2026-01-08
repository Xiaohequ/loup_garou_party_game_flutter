import { GameState, NightSubPhase, Role, Player } from "@/types";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ScrollArea } from "@/components/ui/scroll-area";
import { useState } from "react";

interface NightViewProps {
    gameState: GameState;
    myPlayer: Player;
    onAction: (type: string, payload: any) => void;
}

export function NightView({ gameState, myPlayer, onAction }: NightViewProps) {
    const { subPhase, players } = gameState;
    const isMyTurn =
        (subPhase === NightSubPhase.werewolfTurn && myPlayer.role === Role.werewolf) ||
        (subPhase === NightSubPhase.seerTurn && myPlayer.role === Role.seer) ||
        (subPhase === NightSubPhase.witchTurn && myPlayer.role === Role.witch);

    if (!isMyTurn) {
        return (
            <div className="min-h-screen bg-black flex items-center justify-center p-4">
                <div className="text-center space-y-4">
                    <h1 className="text-4xl text-indigo-400 font-bold animate-pulse">Nuit {gameState.turnCount}...</h1>
                    <p className="text-slate-500">Dormez paisiblement.</p>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-slate-950 p-4 flex items-center justify-center">
            <Card className="w-full max-w-md bg-slate-900 border-slate-800">
                <CardHeader>
                    <CardTitle className="text-center text-slate-100">
                        {subPhase === NightSubPhase.werewolfTurn && "Les Loups Garous se réveillent"}
                        {subPhase === NightSubPhase.seerTurn && "La Voyante se réveille"}
                        {subPhase === NightSubPhase.witchTurn && "La Sorcière se réveille"}
                    </CardTitle>
                </CardHeader>
                <CardContent>
                    {subPhase === NightSubPhase.seerTurn && (
                        <SeerAction players={players} onAction={onAction} revealedId={gameState.seerRevealedId} />
                    )}
                    {subPhase === NightSubPhase.werewolfTurn && (
                        <WerewolfAction players={players} onAction={onAction} votes={gameState.votes} myId={myPlayer.id} />
                    )}
                    {subPhase === NightSubPhase.witchTurn && (
                        <WitchAction
                            players={players}
                            dyingIds={gameState.dyingPlayerIds}
                            hasLife={!gameState.witchUsedLifePotion}
                            hasDeath={!gameState.witchUsedDeathPotion}
                            onAction={onAction}
                        />
                    )}
                </CardContent>
            </Card>
        </div>
    );
}

// --- Sub Components ---

function SeerAction({ players, onAction, revealedId }: { players: Player[], onAction: any, revealedId: string | null }) {
    if (revealedId) {
        const target = players.find(p => p.id === revealedId);
        return (
            <div className="text-center space-y-4">
                <p className="text-lg text-slate-300">Vous avez découvert :</p>
                <div className="text-2xl font-bold text-yellow-400">{target?.name} est {target?.role}</div>
                <Button onClick={() => onAction('NIGHT_DONE', {})}>Terminer</Button>
            </div>
        )
    }

    return (
        <div className="space-y-4">
            <p className="text-slate-400 text-center">Choisissez un joueur à sonder :</p>
            <ScrollArea className="h-[300px]">
                <div className="grid grid-cols-1 gap-2">
                    {players.filter(p => p.isAlive && p.role !== Role.seer).map(p => (
                        <Button key={p.id} variant="outline" onClick={() => onAction('SEER_REVEAL', { targetId: p.id })}>
                            {p.name}
                        </Button>
                    ))}
                </div>
            </ScrollArea>
        </div>
    )
}

function WerewolfAction({ players, onAction, votes, myId }: { players: Player[], onAction: any, votes: Record<string, string>, myId: string }) {
    const alivePlayers = players.filter(p => p.isAlive && p.role !== Role.werewolf);

    return (
        <div className="space-y-4">
            <p className="text-slate-400 text-center">Choisissez une victime :</p>
            <ScrollArea className="h-[300px]">
                <div className="grid grid-cols-1 gap-2">
                    {alivePlayers.map(p => {
                        // Check if any wolf voted for this player
                        const wolfVotes = Object.entries(votes).filter(([, target]) => target === p.id).length;
                        return (
                            <Button
                                key={p.id}
                                variant={votes[myId] === p.id ? "default" : "outline"}
                                className="justify-between"
                                onClick={() => onAction('WEREWOLF_VOTE', { targetId: p.id })}
                            >
                                {p.name}
                                {wolfVotes > 0 && <span className="ml-2 text-red-500 font-bold">{wolfVotes} vote(s)</span>}
                            </Button>
                        );
                    })}
                </div>
            </ScrollArea>
            {Object.keys(votes).length > 0 && new Set(Object.values(votes)).size > 1 && (
                <div className="text-red-500 font-bold text-center animate-pulse bg-red-950/50 p-2 rounded">
                    Veuillez vous mettre d'accord !<br />
                    Sélectionnez un seul villageois.
                </div>
            )}
        </div>
    )
}

function WitchAction({ players, dyingIds, hasLife, hasDeath, onAction }: { players: Player[], dyingIds: string[], hasLife: boolean, hasDeath: boolean, onAction: any }) {
    const [step, setStep] = useState<'life' | 'death'>('life');
    const [actionPayload, setActionPayload] = useState({ save: false, killTargetId: null as string | null });

    const handleSave = (save: boolean) => {
        setActionPayload(prev => ({ ...prev, save }));
        setStep('death');
    };

    const handleKill = (targetId: string | null) => {
        onAction('WITCH_ACTION', { ...actionPayload, killTargetId: targetId });
    };

    const victim = players.find(p => dyingIds.includes(p.id));

    if (step === 'life') {
        if (!hasLife) {
            return (
                <div className="text-center space-y-4">
                    <p className="text-slate-500 italic text-lg">
                        Potion déjà utilisée. <br /> Pas d'info victime.
                    </p>
                    <Button onClick={() => setStep('death')}>Continuer</Button>
                </div>
            )
        }

        return (
            <div className="space-y-6 text-center">
                {victim ? (
                    <div>
                        <p className="text-red-400 font-bold text-xl mb-4">{victim.name} va mourir.</p>
                        <p className="text-slate-400 mb-4">Voulez-vous utiliser votre Potion de Vie ?</p>
                        <div className="flex gap-4 justify-center">
                            <Button onClick={() => handleSave(true)} disabled={!hasLife} className="bg-green-600">Sauver</Button>
                            <Button onClick={() => handleSave(false)} variant="secondary">Ne rien faire</Button>
                        </div>
                    </div>
                ) : (
                    <div>
                        <p className="text-slate-400">Personne n'est mort cette nuit.</p>
                        <Button onClick={() => setStep('death')} className="mt-4">Continuer</Button>
                    </div>
                )}
            </div>
        )
    }

    return (
        <div className="space-y-4">
            <p className="text-slate-400 text-center">Voulez-vous utiliser votre Potion de Mort ?</p>
            <ScrollArea className="h-[200px]">
                <div className="grid grid-cols-1 gap-2">
                    {players.filter(p => p.isAlive && p.id !== victim?.id).map(p => (
                        <Button
                            key={p.id}
                            variant="outline"
                            onClick={() => handleKill(p.id)}
                            className="border-red-900 text-red-400 hover:bg-red-900/20"
                            disabled={!hasDeath}
                        >
                            Tuer {p.name}
                        </Button>
                    ))}
                </div>
            </ScrollArea>
            <Button variant="secondary" className="w-full" onClick={() => handleKill(null)}>Ne rien faire</Button>
        </div>
    )
}
