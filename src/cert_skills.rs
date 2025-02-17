#![no_std]

use multiversx_sc::derive_imports::*;
#[allow(unused_imports)]
use multiversx_sc::imports::*;

/// Enumeración que define las habilidades disponibles en el sistema
/// Se pueden agregar más habilidades según sea necesario
#[type_abi]
#[derive(NestedEncode, NestedDecode, TopEncode, TopDecode, Clone, PartialEq)]
pub enum Skill {
    Skill1,  // Primera habilidad
    Skill2,  // Segunda habilidad
    Skill3,  // Tercera habilidad
    Skill4,  // Cuarta habilidad
    Skill5,  // Quinta habilidad
}

/// Niveles de competencia para cada habilidad
/// Representa el grado de dominio del usuario en una habilidad específica
#[type_abi]
#[derive(NestedEncode, NestedDecode, TopEncode, TopDecode, Clone, PartialEq)]
pub enum Level {
    Basic,        // Nivel básico o principiante
    Intermediate, // Nivel intermedio
    Advanced,     // Nivel avanzado o experto
}

/// Estado actual del certificado
/// Permite trackear si un certificado está activo o ha sido revocado
#[type_abi]
#[derive(NestedEncode, NestedDecode, TopEncode, TopDecode, Clone, PartialEq)]
pub enum Status {
    Active,   // Certificado válido y activo
    Revoked,  // Certificado que ha sido revocado
}

/// Estructura principal del certificado
/// Contiene toda la información relevante sobre una certificación
#[type_abi]
#[derive(NestedEncode, NestedDecode, TopEncode, TopDecode, Clone)]
pub struct Certificate<M: ManagedTypeApi> {
    pub id: usize,                          // Identificador único del certificado
    pub skill: Skill,                       // Tipo de habilidad certificada
    pub level: Level,                       // Nivel de competencia alcanzado
    pub status: Status,                     // Estado actual del certificado
    pub user_address: ManagedAddress<M>,    // Dirección del usuario que posee el certificado
    pub issuer_address: ManagedAddress<M>,  // Dirección del emisor que otorgó el certificado
}

/// Contrato principal para la gestión de certificaciones de habilidades
#[multiversx_sc::contract]
pub trait CertSkills {
    /// Constructor del contrato
    /// Inicializa el contador de certificados a 0
    #[init]
    fn init(&self) {
        self.last_certificate_id().set(0usize);
    }

    /// Endpoint para emitir un nuevo certificado
    /// 
    /// # Argumentos
    /// * `user_address` - Dirección del usuario que recibirá el certificado
    /// * `skill` - Tipo de habilidad a certificar
    /// * `level` - Nivel de competencia alcanzado
    /// 
    /// # Restricciones
    /// * El emisor no puede certificarse a sí mismo
    /// * Un usuario no puede tener dos certificados activos para la misma habilidad
    #[endpoint(issueCertificate)]
    fn issue_certificate(&self, user_address: ManagedAddress, skill: Skill, level: Level) {
        let issuer_address = self.blockchain().get_caller();
        
        // Verifica que el emisor no se auto-certifique
        require!(issuer_address != user_address, "No puedes emitir certificados para ti mismo");

        // Verifica certificados existentes del usuario
        for cert_id in self.address_certificates(&user_address).iter() {
            let cert = self.certificate(cert_id).get();
            require!(
                cert.skill != skill || cert.status == Status::Revoked,
                "Este usuario ya tiene un certificado activo para esta habilidad"
            );
        }

        // Genera nuevo ID de certificado
        let new_id = self.last_certificate_id().get() + 1;

        // Crea el nuevo certificado
        let cert = Certificate {
            id: new_id,
            skill,
            level,
            status: Status::Active,
            user_address: user_address.clone(),
            issuer_address: issuer_address.clone(),
        };

        // Almacena el certificado y actualiza los mapeos
        self.certificate(new_id).set(&cert);
        self.address_certificates(&user_address).insert(new_id);
        self.address_issued_certificates(&issuer_address).insert(new_id);
        self.last_certificate_id().set(new_id);
    }

    /// Endpoint para revocar un certificado existente
    /// 
    /// # Argumentos
    /// * `certificate_id` - ID del certificado a revocar
    /// 
    /// # Restricciones
    /// * Solo el emisor original puede revocar el certificado
    /// * El certificado debe estar activo para poder ser revocado
    #[endpoint(revokeCertificate)]
    fn revoke_certificate(&self, certificate_id: usize) {
        let issuer_address = self.blockchain().get_caller();
        let mut cert = self.certificate(certificate_id).get();
        
        // Verifica que sea el emisor original
        require!(cert.issuer_address == issuer_address, "Solo el emisor puede revocar el certificado");
        require!(cert.status == Status::Active, "El certificado ya está revocado");

        // Actualiza el estado del certificado
        cert.status = Status::Revoked;
        self.certificate(certificate_id).set(&cert);
    }

    /// Vista para obtener un certificado específico por su ID
    #[view(getCertificate)]
    fn get_certificate(&self, certificate_id: usize) -> Certificate<Self::Api> {
        self.certificate(certificate_id).get()
    }

    /// Vista para obtener todos los certificados de un usuario específico
    #[view(getUserCertificates)]
    fn get_user_certificates(&self, user_address: ManagedAddress) -> MultiValueEncoded<Certificate<Self::Api>> {
        let mut result = MultiValueEncoded::new();

        for cert_id in self.address_certificates(&user_address).iter() {
            let cert = self.certificate(cert_id).get();
            result.push(cert);
        }

        result
    }

    /// Vista para obtener los certificados activos emitidos por un emisor específico
    /// Solo devuelve los certificados que tienen estado Active
    #[view(getIssuerCertificates)]
    fn get_issuer_certificates(&self, issuer_address: ManagedAddress) -> MultiValueEncoded<Certificate<Self::Api>> {
        let mut result = MultiValueEncoded::new();

        for cert_id in self.address_issued_certificates(&issuer_address).iter() {
            let cert = self.certificate(cert_id).get();
            if cert.status == Status::Active {
                result.push(cert);
            }
        }

        result
    }

    // 🔹 Mapeos de almacenamiento 🔹

    /// Almacena el último ID de certificado utilizado
    #[view(getLastCertificateId)]
    #[storage_mapper("last_certificate_id")]
    fn last_certificate_id(&self) -> SingleValueMapper<usize>;

    /// Mapeo de ID de certificado a estructura de Certificate
    #[view(getCertificateById)]
    #[storage_mapper("certificate")]
    fn certificate(&self, certificate_id: usize) -> SingleValueMapper<Certificate<Self::Api>>;

    /// Mapeo de dirección de usuario a conjunto de IDs de certificados
    #[view(getUserCertificatesIds)]
    #[storage_mapper("address_certificates")]
    fn address_certificates(&self, user_address: &ManagedAddress) -> SetMapper<usize>;

    /// Mapeo de dirección de emisor a conjunto de IDs de certificados emitidos
    #[view(getIssuerCertificatesIds)]
    #[storage_mapper("address_issued_certificates")]
    fn address_issued_certificates(&self, issuer_address: &ManagedAddress) -> SetMapper<usize>;
}