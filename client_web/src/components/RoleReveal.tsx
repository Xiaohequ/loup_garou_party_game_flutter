import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Role } from '@/types';
import { Eye, Moon, Shield, Sword, User } from 'lucide-react';

interface RoleRevealProps {
    role: Role;
    onConfirm: () => void;
}

export function RoleReveal({ role, onConfirm }: RoleRevealProps) {
    const getRoleIcon = () => {
        switch (role) {
            case Role.werewolf: return <Moon className="h-12 w-12 text-red-500" />;
            case Role.seer: return <Eye className="h-12 w-12 text-blue-500" />;
            case Role.witch: return <Shield className="h-12 w-12 text-purple-500" />;
            case Role.hunter: return <Sword className="h-12 w-12 text-green-500" />;
            default: return <User className="h-12 w-12 text-gray-500" />;
        }
    };

    const getRoleDescription = () => {
        switch (role) {
            case Role.werewolf: return "Réveillez-vous la nuit pour dévorer un villageois.";
            case Role.seer: return "Chaque nuit, découvrez le rôle d'un joueur.";
            case Role.witch: return "Vous avez deux potions : une de vie, une de mort.";
            case Role.hunter: return "Si vous mourez, vous emportez quelqu'un avec vous.";
            default: return "Débusquez les loups-garous et survivez !";
        }
    };

    return (
        <div className="flex items-center justify-center min-h-screen bg-slate-950 p-4">
            <Card className="w-full max-w-md bg-slate-900 border-slate-800 text-slate-100">
                <CardHeader className="text-center">
                    <CardTitle className="text-2xl">Votre Rôle</CardTitle>
                </CardHeader>
                <CardContent className="flex flex-col items-center gap-6">
                    <div className="p-6 bg-slate-800 rounded-full">
                        {getRoleIcon()}
                    </div>

                    <h2 className="text-4xl font-bold uppercase tracking-widest text-primary">
                        {role}
                    </h2>

                    <p className="text-center text-slate-400">
                        {getRoleDescription()}
                    </p>

                    <Button
                        onClick={onConfirm}
                        className="w-full mt-4 bg-primary hover:bg-primary/90 text-primary-foreground"
                    >
                        J'ai compris
                    </Button>
                </CardContent>
            </Card>
        </div>
    );
}
