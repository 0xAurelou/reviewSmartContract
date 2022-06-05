#Permet de dire que l'on va ecrire un contrat Starknet ce qui est different de 
# simplement ecrire du cairo
%lang starknet

#import des modules different modules starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
#import du types uint256 (Entier non signe sur 256) et des operations dessus
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_le, uint256_check
#import des conditions mathemiques inferieurs ou egale et different de zero
from starkware.cairo.common.math import assert_nn_le, assert_not_zero

#import du template de token ERC20 de openzeppelin
from openzeppelin.token.erc20.library import (
    ERC20_name,
    ERC20_symbol,
    ERC20_totalSupply,
    ERC20_decimals,
    ERC20_balanceOf,
    ERC20_allowance,
    ERC20_initializer,
    ERC20_approve,
    ERC20_increaseAllowance,
    ERC20_decreaseAllowance,
    ERC20_transfer,
    ERC20_transferFrom,
    ERC20_mint,
)

#import des modules de declaration et test d'ownership
from openzeppelin.access.ownable import Ownable_initializer, Ownable_only_owner, Ownable_get_owner
#import du syscall (appel systeme) get_caller_address pour recuperer l'adresse
# de la personne qui interagit avec le contrat
from starkware.starknet.common.syscalls import get_caller_address
# import des differentes fonctions definie dans le contrat utils (./contracts/utils.cairo)
from contracts.utils import or, get_is_equal

# import de la constante true
from openzeppelin.utils.constants import TRUE

# Storage var et un mot cle qui permet de declarer des valeurs persistentes et les changer dans vos contrats

# Dans le cas present cap_ ne prend aucun argument en entree et retourne la 
# variable res qui est un Uint256
@storage_var
func cap_() -> (res : Uint256):
end

# Dans le cas present distribution_address ne prend aucun argument en entree et retourne la 
# variable res qui est un felt (Un entier non signe encode sur 252 bits)
@storage_var
func distribution_address() -> (res : felt):
end

# Dans le cas present vault_address ne prend aucun argument en entree et retourne la 
# variable res qui est un felt (Un entier non signe encode sur 252 bits)
@storage_var
func vault_address() -> (res : felt):
end

# Le constructeur est un ensemble d'instructions qui seront effectues une seule fois lors du deploiement du smart contract.
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt,
    symbol : felt,
    decimals : felt,
    initial_supply : Uint256,
    recipient : felt,
    owner : felt,
    _cap : Uint256,
    _distribution_address : felt,
):
    #On verifie bien que _cap est un entier compris entre 0 et 2**256 - 1
    uint256_check(_cap)
    # Verifie que cap est plus grand que uint256 0 (0 sur les 256 bits)
    # Doit renvoyer a chaque fois 0
    let (cap_valid) = uint256_le(_cap, Uint256(0, 0))
    # Normalement on obtient 1 car cap_valid = 0 si, permet de faire fail la fonction
    # en cas de non respect
    # Refacto possible en inversant les conditions
    # let (cap_valid) = uint256_le(Uint256(0,0),_cap) 
    # assert_not_zero(cap_valid)
    assert_not_zero(1 - cap_valid)
    #Verification que l'address n'est pas nul car si address invalid ou nulle address = 0
    assert_not_zero(_distribution_address)
    #Iniatilisation du token avec les 3 arguments name, symbol, decimals
    ERC20_initializer(name, symbol, decimals)
    #Mint des tokens avec l'address qui recoit les token et l'initial_supply qui lui est transferer
    ERC20_mint(recipient, initial_supply)
    # Attribution de la permission ownable a la personne qui a deployer le contrat (l'owner)
    Ownable_initializer(owner)
    # ecriture de _cap dans le storage_var cap_
    cap_.write(_cap)
    # de meme pour la distribution_address
    distribution_address.write(_distribution_address)
    return ()
end

#
# Getters
#

# Le decorateur view permet de recuperer les elements des storage_vars grace au syscall read
# Comme nous n'ecrivons rien dans la blockchain, les view n'utilisent aucun gas
# Dans le cas present nous recuperons juste cap en lisant le storage_var _cap et retournons le resultat
# Sous forme de Uint256
@view
func cap{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res : Uint256):
    let (res : Uint256) = cap_.read()
    return (res)
end

# Nous recuperons le nom du token en appelant la methode ERC20_name fournit par OpenZeppelin
@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
    let (name) = ERC20_name()
    return (name)
end


# Nous recuperons le nom du symbol du token en appelant la methode ERC20_symbol fournit par OpenZeppelin
@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt):
    let (symbol) = ERC20_symbol()
    return (symbol)
end

# Nous recuperons la totalSupply du token en appelant la methode ERC20_totalSupply fournit par OpenZeppelin
@view
func totalSupply{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    totalSupply : Uint256
):
    let (totalSupply : Uint256) = ERC20_totalSupply()
    return (totalSupply)
end

# Nous recuperons le nombre de decimal du token en appelant la methode ERC20_decimals fournit par OpenZeppelin
@view
func decimals{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    decimals : felt
):
    let (decimals) = ERC20_decimals()
    return (decimals)
end

# Nous recuperons la balance du token de l'utilisateur en appelant la methode ERC20_balanceOf fournit par OpenZeppelin
@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    account : felt
) -> (balance : Uint256):
    let (balance : Uint256) = ERC20_balanceOf(account)
    return (balance)
end

# Nous permet de recuperer le nombre de token restant que le spender peut depenser de l'owner
# Si besoin regarder le lien suivant si cela n'est pas claire
# https://www.oreilly.com/library/view/mastering-blockchain-programming/9781839218262/672b8100-dd2e-4d36-8a13-b437dfebee13.xhtml
@view
func allowance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, spender : felt
) -> (remaining : Uint256):
    let (remaining : Uint256) = ERC20_allowance(owner, spender)
    return (remaining)
end

#
# Externals
#
# Le mot cles external permet aux utilisateurs et aux autres contrats d'interagir avec cet fonction
# Ici nous ecrivons dans le storage_var l'addresse du vault que nous venons de creer
@external
func set_vault_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault_address : felt
):
    # Semblable a un require en solidity, si la condition fail nous n'executons pas
    # le reste de la fonction
    Ownable_only_owner()
    # Nous verifions que l'addresse n'est pas nulle
    assert_not_zero(_vault_address)
    # Ecrit l'address du vaul dans le storage_var associe
    vault_address.write(_vault_address)
    return ()
end

# Transfer du token ERC20 entre nous et une addresse
@external
func transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    recipient : felt, amount : Uint256
) -> (success : felt):
    ERC20_transfer(recipient, amount)
    return (TRUE)
end

# Transfer du token ERC20 entre un sender et une addresse
@external
func transferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    sender : felt, recipient : felt, amount : Uint256
) -> (success : felt):
    ERC20_transferFrom(sender, recipient, amount)
    return (TRUE)
end


# Authorize un spender a depenser une partie des tokens detenu par l'owner
@external
func approve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    spender : felt, amount : Uint256
) -> (success : felt):
    ERC20_approve(spender, amount)
    return (TRUE)
end

# Augmentation du nombre des tokens que le spender peut depenser
@external
func increaseAllowance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    spender : felt, added_value : Uint256
) -> (success : felt):
    ERC20_increaseAllowance(spender, added_value)
    return (TRUE)
end

# reduction du nombres de tokens que le spender peut depenser
@external
func decreaseAllowance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    spender : felt, subtracted_value : Uint256
) -> (success : felt):
    ERC20_decreaseAllowance(spender, subtracted_value)
    return (TRUE)
end

# Fonction qui permet a une certaine addresse de mint un certain nombre de token
@external
func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    to : felt, amount : Uint256
):
    alloc_locals
    # Fonction du dessous qui me permet de determiner si nous sommes autoriser a mint
    Authorized_only()
    # recuperons la totalSupply garce a la method OpenZeppelin
    let (totalSupply : Uint256) = ERC20_totalSupply()
    # Lecture du storage_var cap
    let (cap : Uint256) = cap_.read()
    # Verification que le nombre de token que nous voulons mint ajouter a la supply ne
    # depasse pas 2 **256 -1 sinon cela ferait un overflow,ce qui creerait une faille de 
    # securite, OpenZeppelin nous fournit donc des methodes pour verifier cela
    let (local sum : Uint256, is_overflow) = uint256_add(totalSupply, amount)
    # Verification qu'il n'y a pas d'overflow
    assert is_overflow = 0
    # Verification que la somme est inferieur a cap
    let (enough_supply) = uint256_le(sum, cap)
    # Error si ce n'est pas le cas
    assert_not_zero(enough_supply)
    # Error si ce n'est pas le cas
    ERC20_mint(to, amount)
    return ()
end

# Cet fonction n'a aucun decorateur elle est donc privee (non accessible) en dehors du contrat
func Authorized_only{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    # Permet de recuperer l'address de l'owner
    let (owner : felt) = Ownable_get_owner()
    # Recupere l'address du vault
    let (xzkp_address : felt) = vault_address.read()
    # Recupere l'address de la perosnne qui interagit avec le contrat
    let (caller : felt) = get_caller_address()

    # Verification que la personne est bien l'owner
    let (is_owner : felt) = get_is_equal(owner, caller)
    # Verification que la personne est bien proprietaire du vault
    let (is_vault : felt) = get_is_equal(xzkp_address, caller)

    # Sinon erreur
    with_attr error_message("ZkPadToken:: Caller should be owner or vault"):
        let (is_valid : felt) = or(is_vault, is_owner)
        assert is_valid = TRUE
    end

    return ()
end

