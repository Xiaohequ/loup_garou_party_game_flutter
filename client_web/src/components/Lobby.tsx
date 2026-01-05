import { useState } from 'react';
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from "@/components/ui/card"
import { Player } from '@/types';
import { User, CheckCircle } from 'lucide-react';

interface LobbyProps {
    onJoin: (name: string) => void;
    onReady: () => void;
    isConnected: boolean;
    players: Player[];
    myPlayerId: string | null;
}

export function Lobby({ onJoin, onReady, isConnected, players, myPlayerId }: LobbyProps) {
    const [name, setName] = useState("");
    const isJoined = !!myPlayerId;
    const myPlayer = players.find(p => p.id === myPlayerId);

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (name.trim()) {
            onJoin(name);
        }
    }

    return (
        <div className="flex flex-col items-center justify-center min-h-screen bg-slate-50 p-4 gap-6">
            <Card className="w-full max-w-md">
                <CardHeader>
                    <CardTitle className="text-center text-2xl">Loup-Garou Lobby</CardTitle>
                    <CardDescription className="text-center">
                        {isJoined ? "En attente des autres joueurs..." : "Rejoindre la partie"}
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    {!isJoined ? (
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div className="space-y-2">
                                <label htmlFor="name" className="text-sm font-medium">Votre Pseudo</label>
                                <Input
                                    id="name"
                                    placeholder="Entrez votre pseudo"
                                    value={name}
                                    onChange={(e) => setName(e.target.value)}
                                    disabled={!isConnected}
                                />
                            </div>
                            <Button type="submit" className="w-full" disabled={!name.trim() || !isConnected}>
                                {isConnected ? "Rejoindre" : "Connexion au serveur..."}
                            </Button>
                        </form>
                    ) : (
                        <div className="space-y-4">
                            <div className="p-4 bg-slate-100 rounded-lg text-center">
                                <p className="text-sm text-slate-500">Vous êtes connecté en tant que</p>
                                <p className="font-bold text-lg">{myPlayer?.name}</p>
                            </div>
                            <Button
                                className="w-full"
                                variant={myPlayer?.isReady ? "secondary" : "default"}
                                onClick={onReady}
                                disabled={myPlayer?.isReady}
                            >
                                {myPlayer?.isReady ? "Prêt !" : "Je suis prêt"}
                            </Button>
                        </div>
                    )}
                </CardContent>
            </Card>

            {players.length > 0 && (
                <Card className="w-full max-w-md">
                    <CardHeader>
                        <CardTitle className="text-lg">Joueurs ({players.length})</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <ul className="space-y-2">
                            {players.map((p) => (
                                <li key={p.id} className="flex items-center justify-between p-2 bg-slate-100 rounded">
                                    <div className="flex items-center gap-2">
                                        <User className="w-4 h-4 text-slate-500" />
                                        <span className={p.id === myPlayerId ? "font-bold" : ""}>
                                            {p.name} {p.id === myPlayerId && "(Vous)"}
                                        </span>
                                    </div>
                                    {p.isReady && <CheckCircle className="w-5 h-5 text-green-500" />}
                                </li>
                            ))}
                        </ul>
                    </CardContent>
                </Card>
            )}
        </div>
    );
}
