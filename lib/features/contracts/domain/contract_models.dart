import 'dart:convert';

class TenantEntity {
  const TenantEntity({required this.id, required this.name, required this.type, required this.phone, required this.altPhone, required this.idNum, required this.address, required this.email, required this.notes, required this.status, required this.job, required this.familyMembers});
  final String id, name, type, phone, altPhone, idNum, address, email, notes, status, job;
  final int familyMembers;
  factory TenantEntity.fromMap(Map<String, dynamic> m) => TenantEntity(
      id: m['id'] as String, 
      name: m['name'] as String, 
      type: m['type'] as String, 
      phone: m['phone'] as String, 
      altPhone: m['alt_phone'] as String, 
      idNum: m['id_num'] as String, 
      address: m['address'] as String, 
      email: m['email'] as String, 
      notes: m['notes'] as String, 
      status: m['status'] as String,
      job: m['job'] as String? ?? '',
      familyMembers: m['family_members'] as int? ?? 0);
}

class ContractTemplateEntity {
  const ContractTemplateEntity({required this.id, required this.name, required this.terms});
  final String id, name;
  final List<String> terms;
  factory ContractTemplateEntity.fromMap(Map<String, dynamic> m) => ContractTemplateEntity(id: m['id'] as String, name: m['name'] as String, terms: (jsonDecode(m['terms_json'] as String) as List).map((e) => e.toString()).toList());
}

class ContractWitness {
  const ContractWitness({required this.name, required this.detail});
  final String name, detail;
  Map<String, dynamic> toMap() => {'name': name, 'detail': detail};
  factory ContractWitness.fromMap(Map<String, dynamic> m) => ContractWitness(name: m['name'] as String, detail: m['detail'] as String);
}

class ContractEntity {
  const ContractEntity({required this.id, required this.unitId, required this.tenantId, required this.createdDate, required this.startDate, required this.endDate, required this.rent, required this.currency, required this.frequency, required this.customInterval, required this.deposit, required this.graceDays, required this.status, required this.prevContractId, required this.increasePct, required this.witnesses, required this.terms});
  final String id, unitId, tenantId, createdDate, startDate, endDate, currency, frequency, customInterval, status;
  final String? prevContractId;
  final double rent, deposit, increasePct;
  final int graceDays;
  final List<ContractWitness> witnesses;
  final List<String> terms;

  factory ContractEntity.fromMap(Map<String, dynamic> m) => ContractEntity(
        id: m['id'] as String, unitId: m['unit_id'] as String, tenantId: m['tenant_id'] as String,
        createdDate: m['created_date'] as String, startDate: m['start_date'] as String, endDate: m['end_date'] as String,
        rent: (m['rent'] as num).toDouble(), currency: m['currency'] as String, frequency: m['frequency'] as String,
        customInterval: m['custom_interval'] as String, deposit: (m['deposit'] as num).toDouble(), graceDays: m['grace_days'] as int,
        status: m['status'] as String, prevContractId: m['prev_contract_id'] as String?, increasePct: (m['increase_pct'] as num).toDouble(),
        witnesses: (jsonDecode(m['witnesses_json'] as String) as List).map((e) => ContractWitness.fromMap(e as Map<String, dynamic>)).toList(),
        terms: (jsonDecode(m['terms_json'] as String) as List).map((e) => e.toString()).toList(),
      );
}

abstract interface class ContractRepository {
  Future<List<TenantEntity>> getTenants();
  Future<void> upsertTenant(TenantEntity t);
  Future<void> deleteTenant(String tid);
  Future<void> deleteContract(String cid);
  Future<List<ContractTemplateEntity>> getTemplates();
  Future<List<ContractEntity>> getContracts();
  Future<void> createContract(ContractEntity c);
  Future<void> addCustomTerm(String cid, String term);
  Future<void> generateNextDue(String cid);
  Future<void> renewContract(ContractEntity oldC, String newId, String start, String end, double newRent, double pct);
  Future<void> terminateContract(String cid, String type, double amt, String notes);
  Future<void> updateContract(ContractEntity c);

}