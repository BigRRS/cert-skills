# CertSkills

CertSkills és un contracte intel·ligent desenvolupat en MultiversX per gestionar certificats de competències en una blockchain. Permet als emissors crear, revocar i consultar certificats de manera segura i transparent.

## 📌 Característiques
- Emissió de certificats digitals associats a una adreça d'usuari.
- Nivells de competència configurables (Bàsic, Intermedi, Avançat).
- Possibilitat de revocació per part de l'emissor.
- Consultes per ID de certificat, usuari o emissor.

## 🚀 Instal·lació i Configuració
### Prerequisits
- [MultiversX SDK (mxpy)](https://github.com/multiversx/mx-sdk-py-cli)
- Bash Shell
- Git

### Clonar el repositori
```bash
git clone https://github.com/BigRRS/cert-skills.git
cd cert-skills
```

## 🔧 Ús del Script Bash
El projecte inclou un script Bash per interactuar amb el contracte.

### Executar el menú interactiu
```bash
./gestor_certificats.sh
```

### Opcions disponibles
1️⃣ **Emetre un nou certificat**
2️⃣ **Consultar un certificat per ID**
3️⃣ **Consultar certificats d'un usuari**
4️⃣ **Consultar certificats emesos per un emissor**
5️⃣ **Sortir**

## 📜 Format del Certificat
Cada certificat conté la següent informació:
```json
{
  "id": 1,
  "skill": "Skill2",
  "level": "Intermediate",
  "status": "Active",
  "user_address": "erd1...",
  "issuer_address": "erd1..."
}
```

## 🛠 Desenvolupament
Per compilar i desplegar el contracte:
```bash
mxpy contract build
mxpy contract deploy --pem wallet.pem --proxy https://devnet-gateway.multiversx.com
```

## 🏗 Contribució
1. Fes un fork del repositori.
2. Crea una nova branca (`git checkout -b feature-nova`).
3. Fes els teus canvis i comita'ls (`git commit -m 'Afegeix nova funcionalitat'`).
4. Puja la branca (`git push origin feature-nova`).
5. Fes una Pull Request.

## 📄 Llicència
Aquest projecte està sota la llicència MIT.

